<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" encoding="UTF-8" />

    <xsl:param name="title" />
    <xsl:param name="header" />
    <xsl:param name="path" />
    <xsl:param name="color-base00" />
    <xsl:param name="color-base07" />
    <xsl:param name="color-base0D" />
    <xsl:param name="color-base0E" />

    <xsl:variable name="custom-colors">
        <xsl:if test="$color-base00 != ''">
            <xsl:text>--color-base00: </xsl:text>
            <xsl:value-of select="$color-base00" />
            <xsl:text>;</xsl:text>
        </xsl:if>

        <xsl:if test="$color-base07 != ''">
            <xsl:text>--color-base07: </xsl:text>
            <xsl:value-of select="$color-base07" />
            <xsl:text>;</xsl:text>
        </xsl:if>

        <xsl:if test="$color-base0D != ''">
            <xsl:text>--color-base0D: </xsl:text>
            <xsl:value-of select="$color-base0D" />
            <xsl:text>;</xsl:text>
        </xsl:if>

        <xsl:if test="$color-base0E != ''">
            <xsl:text>--color-base0E: </xsl:text>
            <xsl:value-of select="$color-base0E" />
            <xsl:text>;</xsl:text>
        </xsl:if>
    </xsl:variable>

    <xsl:template match="/">
        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>

        <html>
            <head>
                <title><xsl:value-of select="$title" /></title>

                <meta name="version" content="2.0.1" />
                <meta name="viewport" content="initial-scale=1, shrink-to-fit=no, viewport-fit=cover, width=device-width, height=device-height" />

                <style><![CDATA[
:root {
	--color-base00: #FFFFFF;
	--color-base07: #202020;
	--color-base0D: #3777E6;
	--color-base0E: #AD00A1;
	--theme-background: var(--color-base00);
	--theme-link-directory: var(--color-base0D);
	--theme-link-file: var(--color-base07);
	--theme-link-highlight: var(--color-base0E);
	--theme-link-hover: var(--color-base0E)
}

@media(prefers-color-scheme: dark) {
	:root {
		--color-base00: #2D2D2D;
		--color-base07: #F2F0EC;
		--color-base0D: #6699CC;
		--color-base0E: #CC99CC
	}
}

* {
	box-sizing: border-box
}

html {
	background-color: var(--theme-background);
	font-family: SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
	font-size: 100%;
	color: var(--color-base07);
}
a {
  color: var(--color-base0E);
}


/*body {margin: 3.5rem}*/

.asset-list {
	/*display: block;*/
	list-style: none;
	margin: 0;
	padding: 0
}

/*.asset-item {display: block}*/

.asset-item--directory {
	color: var(--theme-link-directory)
}

.asset-item--file {
	color: var(--theme-link-file)
}

/*.asset-item--directory+.asset-item--file {margin-top: 1rem}*/

.asset-link {
	/*display: block;*/
	line-height: 1.7;
	opacity: 1;
	overflow: hidden;
	text-overflow: ellipsis;
	transition: color 100ms, opacity 100ms;
	white-space: nowrap
}

.asset-link:any-link {
	color: inherit;
	text-decoration: none
}

.asset-link:focus,
.asset-link:hover {
	color: var(--theme-link-hover)
}

.asset-link:focus {
	outline: none
}

.asset-mark {
	position: relative;
	background-color: transparent;
	color: var(--theme-link-highlight);
	/*display: inline-block*/
}

.asset-mark::before {
	position: absolute;
	top: 50%;
	right: 0;
	left: 0;
	background-color: var(--theme-link-highlight);
	border-radius: 1px;
	content: "";
	transform: translateY(-50%) translateY(0.5em);
	width: auto;
	height: 2px
}

.asset-item--filtered>.asset-link {
	opacity: .4
}

.asset-item--filtered>.asset-link:focus,
.asset-item--filtered>.asset-link:hover {
	opacity: 1
}
]]></style>

                <xsl:if test="normalize-space($custom-colors) != ''">
                    <style>
                        <xsl:text>:root {</xsl:text>
                            <xsl:value-of select="$custom-colors" />
                        <xsl:text>}</xsl:text>
                    </style>
                </xsl:if>
            </head>
            <body>
                <xsl:if test="$header != ''">
                  <header><xsl:value-of select="$header" disable-output-escaping="yes"/></header>
                </xsl:if>
                <ol aria-label="asset list" is="asset-list" class="asset-list">
                    <xsl:if test="$path!='' and $path!='/'">
                    <li class="asset-link asset-link--directory"><a href="../">../</a></li>
                    </xsl:if>
                    <xsl:for-each select="list/*">
                    <xsl:if test="text() != 'favicon.ico'">
                        <li is="asset-item">
                            <xsl:attribute name="class">
                                <xsl:text>asset-item asset-item--</xsl:text>
                                <xsl:value-of select="name()" />
                            </xsl:attribute>

                            <a is="asset-link">
                                <xsl:attribute name="aria-label">
                                    <xsl:value-of select="name()" />
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="." />
                                </xsl:attribute>

                                <xsl:attribute name="data-name">
                                    <xsl:value-of select="." />
                                </xsl:attribute>

                                <xsl:attribute name="href">
                                    <xsl:value-of select="." />
                                    <xsl:if test="name() = 'directory'">
                                        <xsl:text>/</xsl:text>
                                    </xsl:if>
                                </xsl:attribute>

                                <xsl:attribute name="class">
                                    <xsl:text>asset-link asset-link--</xsl:text>
                                    <xsl:value-of select="name()" />
                                </xsl:attribute>

                                <xsl:value-of select="." />
                                <xsl:if test="name() = 'directory'">
                                    <xsl:text>/</xsl:text>
                                </xsl:if>
                            </a>
                        </li>
                      </xsl:if>
                    </xsl:for-each>
                </ol>

                <script><![CDATA[
const CustomElement = ParentClass => class CustomElement extends ParentClass {
    static define() {
        customElements.define(this.tagName, this, {
            extends: this.tagType
        })
    }
    connectedCallback() {
        if (this.isConnected && this.mount instanceof Function) {
            this.mount()
        }
    }
    getCustomElement(customElement) {
        return this.querySelector(`[is="${customElement.tagName}"]`)
    }
};
class AssetLink extends(CustomElement(HTMLAnchorElement)) {
    static tagName = "asset-link";
    static tagType = "a";
    highlighted = false;
    highlight(highlightedGraphemes) {
        const regExp = new RegExp(`^(${highlightedGraphemes})`, "iu");
        this.highlighted = highlightedGraphemes !== "" && regExp.test(this.name);
        if (this.highlighted) {
            const template = '<mark class="asset-mark">$1</mark>';
            this.innerHTML = this.name.replace(regExp, template)
        } else {
            this.textContent = this.name
        }
        this.classList.toggle("asset-link--highlighted", this.highlighted)
    }
    get name() {
        return this.dataset.name
    }
    get type() {
        if (this.classList.contains("asset-link--directory")) {
            return "directory"
        }
        if (this.classList.contains("asset-link--file")) {
            return "file"
        }
        return ""
    }
}
class AssetItem extends(CustomElement(HTMLLIElement)) {
    static tagName = "asset-item";
    static tagType = "li";
    link = this.getCustomElement(AssetLink);
    highlight(highlightedGraphemes) {
        this.link.highlight(highlightedGraphemes);
        const filtered = highlightedGraphemes === "" || this.link.highlighted;
        this.ariaHidden = filtered ? null : true;
        this.classList.toggle("asset-item--filtered", !filtered)
    }
    get highlighted() {
        return this.link.highlighted
    }
    focus() {
        this.link.focus()
    }
}
class AssetList extends(CustomElement(HTMLOListElement)) {
    static tagName = "asset-list";
    static tagType = "ol";
    highlightedGraphemes = "";
    keystroke = this.keystroke.bind(this);
    highlight(key) {
        if (key === "") {
            this.highlightedGraphemes = ""
        } else {
            this.highlightedGraphemes += key.toLocaleLowerCase()
        }
        let firstHighlightedAssetItem;
        for (const assetItem of this.children) {
            assetItem.highlight(this.highlightedGraphemes);
            if (firstHighlightedAssetItem === undefined && assetItem.highlighted) {
                firstHighlightedAssetItem = assetItem
            }
        }
        if (firstHighlightedAssetItem === undefined) {
            if (this.highlightedGraphemes !== "") {
                this.highlight("")
            }
            return
        }
        firstHighlightedAssetItem.focus();
        firstHighlightedAssetItem.scrollIntoView({
            behavior: "smooth",
            block: "nearest"
        })
    }
    mount() {
        document.body.addEventListener("keyup", this.keystroke)
    }
    keystroke({
        key: key
    }) {
        if (key === "Escape") {
            this.highlight("");
            return
        }
        const notGrapheme = key.length !== 1;
        if (notGrapheme) {
            return
        }
        this.highlight(key)
    }
}

function main() {
    AssetLink.define();
    AssetItem.define();
    AssetList.define()
}
document.addEventListener("DOMContentLoaded", main);
]]></script>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
<!--
https://github.com/gibatronic/ngx-superbindex/releases/download/v2.0.1/superbindex.xslt
-->
