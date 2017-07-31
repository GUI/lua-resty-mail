local rfc2822_date = require "resty.mail.rfc2822_date"

-- Tests assume TZ="America/Denver" environment variable set.
describe("rfc2822_date", function()
  it("ignores system locale", function()
    local orig_locale = os.setlocale()
    assert(os.setlocale("fr_FR"))
    assert.equal("jeu., 27 juil. 2017", os.date("%a, %d %b %Y", 1501211178))

    local date = rfc2822_date(1501211178)
    assert.equal("Thu, 27 Jul 2017 21:06:18 -0600", date)

    assert(os.setlocale(orig_locale))
  end)
end)
