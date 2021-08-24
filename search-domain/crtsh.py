import requests
from simplejson.errors import JSONDecodeError
import time
from datetime import datetime

def myex(e, msg):
    largs = list(e.args)
    if len(largs)==1 and isinstance(largs, str):
        largs[0] = largs[0]+' '+msg
    else:
        largs.append(msg)
    e.args = tuple(largs)
    return e

def get_js(url, tries=3, **kvargs):
    params={k:v for k,v in kvargs.items() if v is not None}
    r = None
    try:
        r = requests.get(url, params=params)
    except Exception as e:
        if tries==0:
            raise myex(e, 'in request.get("%s")' % url)
    if r is None or r.status_code != 200:
        time.sleep(10)
        return get_js(url, tries=tries-1, **kvargs)
    try:
        return r.json()
    except Exception as e:
        if tries==0:
            raise myex(e, 'in request.get("%s").json()' % url)
    time.sleep(10)
    return get_js(url, tries=tries-1, **kvargs)

def strtodate(s):
    if s in (None, ""):
        return None
    if len(s)>=19:
        return datetime.strptime(s[:19], "%Y-%m-%dT%H:%M:%S")
    raise Exception("Not date "+s)

class CrtSH:
    def __init__(self):
        self.url = "https://crt.sh"

    def get(self, dom, exclude='expired', deduplicate='Y', **kvargs):
        kvargs['output']='json'
        kvargs['dNSName']=dom
        rt = get_js("https://crt.sh", **kvargs)
        for r in rt:
            for k in ('entry_timestamp', 'not_before', 'not_after'):
                v = r.get(k)
                if isinstance(v, str):
                    r[k]=strtodate(v)
        return rt
