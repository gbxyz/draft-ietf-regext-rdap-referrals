all: build

build:
	@mmark draft-ietf-regext-rdap-redirects.md > draft-ietf-regext-rdap-redirects.xml
	@xml2rfc --html draft-ietf-regext-rdap-redirects.xml

clean:
	@rm -f *xml *html
