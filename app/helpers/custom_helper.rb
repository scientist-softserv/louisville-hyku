# frozen_string_literal: true

module CustomHelper

    def search_list_dt(f)
        (f).downcase!.tr(" ", "-").chop + " " + "metadata-heading"
    end

    def search_list_dd(f)
        (f).downcase!.tr(" ", "-").chop + " " + "metadata-content"
    end

end