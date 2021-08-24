#!/usr/bin/python3
# -*- coding: utf-8 -*-

import json
import os
import re
import sys
import time
from datetime import date, datetime, timedelta
from unicodedata import normalize
from urllib.parse import urlencode, urljoin
from functools import lru_cache
from munch import Munch
from crtsh import CrtSH

import bs4
import requests

import enchant

url_afraid = "https://freedns.afraid.org/domain/registry/page-%s.html"
s = requests.Session()
s.headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:54.0) Gecko/20100101 Firefox/54.0',
    "Cache-Control": "no-cache",
    "Pragma": "no-cache",
    "Expires": "Thu, 01 Jan 1970 00:00:00 GMT",
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
    'Accept-Encoding': 'gzip, deflate, br',
    'DNT': '1',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    "X-Requested-With": "XMLHttpRequest",
}

now = datetime.now().date()
ok_words = dict()
ko_wrods = set()
word_dict = {
    "es": enchant.Dict("es_ES"),
    "en": enchant.Dict("en_US")
}
re_vowel = re.compile(r"[aeiou]", re.IGNORECASE)
re_sp = re.compile(r"\s+")
re_date = re.compile(r'\d+/\d+/\d+')
crtSH = CrtSH()

def srtdate(s, frm="%Y-%m-%d"):
    if isinstance(s, str):
        if len(s)==10:
            return datetime.strptime(s, frm).date()
        if len(s)==16:
            return datetime.strptime(s, frm+" %H:%M")
        raise Exception("No es una fecha: "+s)
    if isinstance(s, date):
        return s.strftime(frm)
    if isinstance(s, datetime):
        return s.strftime(frm+" %H:%M")
    raise Exception("No es una fecha: "+str(s))

def safe_srtdate(*args, **kvargs):
    try:
        return srtdate(*args, **kvargs)
    except:
        pass
    return None

def date_hook(o):
    for k, v in o.items():
        if isinstance(v, str):
            nv = safe_srtdate(v)
            if nv is not None:
                o[k]=nv
    return o

def json_default(o):
    if isinstance(o, Domain):
        return o.to_dict()
    if isinstance(o, date):
        return o.strftime('%Y-%m-%d')
    if isinstance(o, datetime):
        return o.strftime('%Y-%m-%d %H:%M')


def get(url, tries=4):
    r = None
    try:
        r = s.get(url)
    except Exception as e:
        if tries == 0:
            raise
    if r is None or r.status_code != 200:
        time.sleep(10)
        return get(url, tries=tries - 1)
    soup = bs4.BeautifulSoup(r.text, "lxml")
    return soup

def get_text(n):
    for br in n.findAll("br"):
        br.replace_with("\n")
    n = n.get_text().strip()
    n = n.split("\n")
    n = [re_sp.sub(" ", i).strip() for i in n]
    n = "\n".join(i for i in n if i)
    return n.strip()

def read_letsencrypt(dom):
    r = Munch(
        total=0,
        dates=[],
        sub=set(),
    )
    for crt in crtSH.get(dom):
        if "Let's Encrypt" not in crt['issuer_name']:
            continue
        for val in (crt['common_name'], crt['name_value']):
            for v in val.split():
                if v.startswith("*."):
                    v = v[2:]
                if v.endswith("."+dom):
                    r.sub.add(v)
        r.dates.append(crt['not_before'].date())
        r.total = r.total + 1
    r.sub = sorted(r.sub)
    return r


def get_lang_word(a):
    langs = set()
    if len(a) < 2:
        return langs
    if not re_vowel.search(a):
        return langs
    if a in ko_wrods:
        return langs
    if a in ok_words.keys():
        return ok_words[a]
    for k, wd in word_dict.items():
        if wd.check(a):
            langs.add(k)
            continue
        for s in wd.suggest(a):
            w = normalize('NFKD', s).encode('ascii', 'ignore')
            if w == a:
                langs.add(k)
    if len(langs) == 0:
        ko_wrods.add(a)
        return langs
    ok_words[a] = langs
    return langs


def get_lang_phrase(*args):
    langs = set()
    for phrase in args:
        for word in phrase.split("-"):
            langs = langs.union(get_lang_word(word))
    if len(langs) == 0:
        return None
    return tuple(sorted(langs))


def get_domains(soup):
    doms = []
    for tr in soup.findAll("tr"):
        tds = tr.findAll("td")
        if len(tds) == 4:
            if tds[1].get_text().strip() in ("public", "private"):
                doms.append(Domain(tds))
    return doms


class Domain():

    @staticmethod
    def from_afraid():
        domains = []
        i = 0
        while True:
            i += 1
            soup = get(url_afraid % i)
            doms = get_domains(soup)
            if len(doms) == 0:
                domains = list(set(domains))
                domains.sort(key=lambda d: d.key)
                return domains
            domains.extend(doms)
        return domains

    @staticmethod
    def load(*args):
        domains = []
        for fl in args:
            ext = fl.split(".")[-1]
            with open(fl, "r") as f:
                if ext == "txt":
                    for l in f.readlines():
                        l = l.strip()
                        if len(l) > 0:
                            domains.append(Domain(tuple(l.split())))
                elif ext == "json":
                    domains.extend([Domain(j) for j in json.load(f, object_hook=date_hook)])
        domains = sorted(set(domains), key=lambda d: d.key)
        return domains

    @staticmethod
    def store(fl, domains):
        domains.sort(key=lambda d: d.key)
        ext = fl.split(".")[-1]
        with open(fl, "w") as f:
            if ext == "txt":
                for d in domains:
                    f.write(str(d) + "\n")
            elif ext == "json":
                json.dump(domains, f, sort_keys=True, indent=4, default=json_default)

    def __init__(self, data):
        self._letsencrypt = None
        self._langs = None
        if isinstance(data, tuple):
            self.dom = data[3]
            self.public = data[1] == "1"
            self.create = srtdate(data[0])
            self.hosts = int(data[2])
        elif isinstance(data, dict):
            self.create = data.get("create")
            self.owner = data.get("owner")
            self.dom = data.get("dom")
            self.public = data.get("public")
            self.hosts = data.get("hosts")
            self._letsencrypt = data.get("letsencrypt")
            self._langs = data.get("langs")
        else:
            self.dom = data[0].find("a").get_text().strip()
            self.public = data[1].get_text().strip() == "public"
            self.owner = data[2].find("a").get_text().strip()
            self.hosts = int(data[0].find(
                "span").get_text().strip()[1:].split(" ")[0])
            str_create = re_date.search(data[3].get_text()).group()
            self.create = srtdate(str_create, "%m/%d/%Y")

    @property
    def top(self):
        return self.dom[self.dom.rindex(".") + 1:]

    @property
    def name(self):
        return self.dom[:self.dom.rindex(".")]

    @property
    def key(self):
        return tuple(reversed(self.dom.split(".")))

    @property
    def old(self):
        return (datetime.today().date() - self.create).days

    @property
    def recent_letsencrypt(self):
        recent = 0
        day_limit = 7
        for d in self.letsencrypt.dates:
            days = (now - d).days
            if (days) < day_limit:
                recent += 1
        return recent

    def to_dict(self):
        dct = self.__dict__.copy()
        dct['langs'] = self.langs
        dct['letsencrypt'] = self._letsencrypt
        for k in list(dct.keys()):
            if k[0] == '_':
                del dct[k]
        return dct

    @property
    @lru_cache(maxsize=None)
    def langs(self):
        if self._langs:
            return self._langs
        steps = self.dom.split(".")[:-1]
        steps.append(self.dom.replace(".", ""))
        langs = get_lang_phrase(*steps)
        return langs

    def is_cool(self):
        if self.dom.count(".") > 1:
            return False
        if self.dom.count("--") > 0:
            return False
        lname = len(self.name)
        if lname < 3:
            return True
        if lname > 14:
            return False
        if self.name.isdigit() and lname < 5:
            return True
        if not re_vowel.search(self.name):
            return False
        if lname < 4 and self.dom.count("-") == 0:
            return True
        if len(self.top) > 4 and not get_lang_word(self.top):
            return False
        if self.langs:
            return True
        return False

    @property
    def letsencrypt(self):
        if self._letsencrypt is None:
            self._letsencrypt=read_letsencrypt(self.dom)
        return self._letsencrypt

    def __hash__(self):
        return hash(self.dom)

    def __eq__(self, other):
        return self.dom == other.dom

    def __str__(self):
        return "%s %s %6s %s" % (self.create, int(self.public), self.hosts, self.dom)
