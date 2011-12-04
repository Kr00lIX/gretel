ActionView::Helpers::TagHelper::BOOLEAN_ATTRIBUTES << :itemscope

module Gretel
  module HelperMethods
    include ActionView::Helpers::UrlHelper
    def controller # hack because ActionView::Helpers::UrlHelper needs a controller method
    end
    
    def self.included(base)
      base.send :helper_method, :breadcrumb_for, :breadcrumb
    end
    
    def breadcrumb(*args)
      options = args.extract_options!
      name, params = args[0], args[1..-1]
      
      if name
        @_breadcrumb_name = name
        @_breadcrumb_params = params
      else
        if @_breadcrumb_name
          crumb = breadcrumb_for(@_breadcrumb_name, *@_breadcrumb_params, options)
        elsif options[:show_root_alone]
          crumb = breadcrumb_for(:root, options)
        end
      end
      
      if crumb && options[:pretext]
        crumb = options[:pretext].html_safe + " " + crumb
      end
      
      crumb
    end
    
    def breadcrumb_for(*args)
      options = args.extract_options!
      link_last = options[:link_last]
      options[:link_last] = true
      separator = (options[:separator] || "&gt;").html_safe
      link_options = options[:semantic] ? {
        :itemprop => 'title url'
      } : {}

      name, params = args[0], args[1..-1]
      
      crumb = Crumbs.get_crumb(name, *params)
      out = [link_to_if(link_last, crumb.link.text, crumb.link.url, crumb.link.options.reverse_merge(link_options))]
      
      while parent = crumb.parent
        last_parent = parent.name
        crumb = Crumbs.get_crumb(parent.name, *parent.params)
        out.unshift(link_to(crumb.link.text, crumb.link.url, crumb.link.options.reverse_merge(link_options)))
      end
      
      # TODO: Refactor this
      if options[:autoroot] && name != :root && last_parent != :root
        crumb = Crumbs.get_crumb(:root)
        out.unshift(link_to(crumb.link.text, crumb.link.url, crumb.link.options.reverse_merge(link_options)))
      end
      
      out.map! { |link| %Q{<span itemscope itemtype="http://data-vocabulary.org/Breadcrumb">#{link}</span>} } if options[:semantic]
      
      # add separarator
      out = out[0...-1].map! { |link| "#{link} #{separator} ".html_safe } + out[-1..-1]
      
      out.map! { |link| content_tag options[:wrapper_tag], link } if options[:wrapper_tag]

      out.join("").html_safe 
    end
  end
end