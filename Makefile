VERSION="02"

all: build

build:
	@mmark draft-brown-rdap-referrals.md > draft-brown-rdap-referrals-$(VERSION).xml
	@xml2rfc --html draft-brown-rdap-referrals-$(VERSION).xml

clean:
	@rm -f *xml *html
