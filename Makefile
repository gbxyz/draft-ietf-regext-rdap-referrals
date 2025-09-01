VERSION="00"

all: build

build:
	@mmark draft-ietf-regext-rdap-referrals.md > draft-ietf-regext-rdap-referrals-$(VERSION).xml
	@xml2rfc --html draft-ietf-regext-rdap-referrals-$(VERSION).xml

clean:
	@rm -f *xml *html
