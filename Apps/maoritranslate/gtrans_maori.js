(function(){

    // read cookie by name
    function readCookie(name){
        c = document.cookie.split('; ');
        cookies = {};
        for(i=c.length-1; i>=0; i--){
           C = c[i].split('=');
           cookies[C[0]] = C[1];
        }
        return cookies[name];
    }

    // Add root
    $("#moresearches ul").append("<li><div id='google_translate_element'><div id='g_logo'></div><a id='gtran_text' class='' href='javascript:void(0)'></a></div></li>");

    // CSS
    $("head").append('<style>\
        #google_translate_element {\
            display: inline;\
        }\
        #google_translate_element > .m::after {\
				content: "Translate to te reo MÄori";\
		}\
		#google_translate_element > .e::after {\
			content: "Translate to English";\
		}\
        .skiptranslate {\
            display: none;\
        }\
        body {\
            top: 0px !important;\
        }\
        #g_logo{\
            background: url(http://gss.ebscohost.com/cwu/apps/mgt/gi.png);\
            height: 16px;\
            width: 16px;\
            background-size: cover;\
            display: inline-block;\
            position: relative;\
            top: 3px;\
            left: 1px;\
            margin-right: 6px;\
		}\
    </style>');

    // Init gtrans
    function googleTranslateElementInit() {
        new google.translate.TranslateElement({pageLanguage: 'en', includedLanguages: 'mi', layout: google.translate.TranslateElement.InlineLayout.SIMPLE, autoDisplay: false}, 'google_translate_element');
    }

    // escape scope
    window.googleTranslateElementInit = googleTranslateElementInit;

    // fetch script
    $.getScript("//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit");

    // Check state
    function changeText(){
        if (!readCookie("googtrans") || readCookie("googtrans") == "/en/en"){
            $("#google_translate_element #gtran_text").addClass('m');
            $("#google_translate_element #gtran_text").removeClass('e');
        } else if (readCookie("googtrans") == "/en/mi"){
            $("#google_translate_element #gtran_text").addClass('e');
            $("#google_translate_element #gtran_text").removeClass('m');
        }
    }

    $("body").contents().on('click', '#google_translate_element #gtran_text.m', function() {

        // no cookie
        if (!readCookie("googtrans")){
            $(".goog-te-menu-frame.skiptranslate").contents().find("a.goog-te-menu2-item")[0].click();
        } else {
            jQuery("div[class='skiptranslate']:not([id]) iframe").contents().find("button:contains('Translate')")[0].click();
        }

        $("#google_translate_element #gtran_text").addClass('e');
        $("#google_translate_element #gtran_text").removeClass('m');
    });

    $("body").contents().on('click', '#google_translate_element #gtran_text.e', function() {

        jQuery("div[class='skiptranslate']:not([id]) iframe").contents().find("button:contains('Show original')")[0].click();
        $("#google_translate_element #gtran_text").addClass('m');
        $("#google_translate_element #gtran_text").removeClass('e');

    });

    // wait for start
    var checkInt = setInterval(function(){
        if ($(".skiptranslate").length > 0){
            changeText();
            clearInterval(checkInt);
        }
    }, 100);

})();
