/* 
 *   jQuery Sticky Plugin 1.0.1
 *   https://github.com/garethdn/jquery-sticky
 *
 *   Copyright 2013, Bruno Tarmann & Gareth Nolan
 *   http://tarmann.com.br
 *   http://ie.linkedin.com/in/garethnolan/

 *   Based on jQuery Boilerplate by Zeno Rocha with the help of Addy Osmani
 *   http://jqueryboilerplate.com
 *
 *   Licensed under the MIT license:
 *   http://www.opensource.org/licenses/MIT
 */

;(function ( $, window, document, undefined ) {

	var pluginName = "sticky";
	var defaults = {
		stickyClass: 'sdui-sticky-content',
        anchorClass: 'sdui-sticky-content-anchor',
        activeClass: 'is-active',
        buffer: 0
	};

	function Plugin ( element, options ) {
		this.element = element;

		this.settings = $.extend( {}, defaults, options );
		this._defaults = defaults;
		this._name = pluginName;
		this.init();
	}

	Plugin.prototype = {
		init: function () {
			$(this.element).addClass(this.settings.stickyClass);

			this.elementWidth = $(this.element).width();
			this.elementHeight = $(this.element).outerHeight();
			this.elementAnchor = this.createAnchor();

			this.bindEvents();
		},

		bindEvents: function () {
			var self = this;

			$(window).scroll( function () {
				self.refreshPosition();
			});
		},

		createAnchor: function () {
			return $('<div>').addClass(this.settings.anchorClass).insertBefore(this.element);
		},

		refreshPosition: function () {
			var scrollTop = $(window).scrollTop(),
	            elementAnchorTop = this.elementAnchor.offset().top;

	        if ( (scrollTop + this.settings.buffer) > elementAnchorTop ) {
	            this.fixElement()
	        } else {
	            this.releaseElement();
	        }
		},

		fixElement: function () {
			$(this.element).css({ 
            	position: 'fixed',
            	top: this.settings.buffer + 'px',
            	'z-index': 1000,
            	'width': this.elementWidth
            }).addClass(this.settings.activeClass);

            $(this.elementAnchor).height(this.elementHeight);
		},

		releaseElement: function () {
			$(this.element).css({ 
            	position: 'relative',
            	top: ''
            }).removeClass(this.settings.activeClass);

            $(this.elementAnchor).height(0);
		}
	};

	$.fn[ pluginName ] = function ( options ) {
		return this.each(function() {
			if ( !$.data( this, "plugin_" + pluginName ) ) {
				$.data( this, "plugin_" + pluginName, new Plugin( this, options ) );
			}
		});
	};

})( jQuery, window, document );