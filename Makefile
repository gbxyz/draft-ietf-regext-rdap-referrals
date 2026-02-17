all: build

build:
	@mmark draft-ietf-regext-rdap-referrals.md > draft-ietf-regext-rdap-referrals.xml
	@xml2rfc --html draft-ietf-regext-rdap-referrals.xml

clean:
	@rm -f *xml *html
