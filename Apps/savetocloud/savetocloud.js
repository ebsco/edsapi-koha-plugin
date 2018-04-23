(function(){

    $.ajax({
        url : "//widgets.ebscohost.com/prod/customlink/lightbox/lightbox.js",
        dataType : "script",
        cache : true
    }).done(function () {
        $("#userresults .searchresults tr .pdflink:not([href^='javascript:LoginRequired()'])").each(function() {
            var e = $(this).parent().parent().parent();
            var obj = {
                "title": e.find(".title")[0].text,
                "link": e.find(".pdflink")[0].href
            }
            e.find(".links").append('\
                <a href="javascript:_ebscoSaveToCloud(\'' + encodeURIComponent(JSON.stringify(obj)) + '\')"\
                >\
                    Save PDF to Cloud\
                </a>\
            ');
        });

        $(".customLink.pdflink:not([href^='javascript:LoginRequired()'])").first().each(function() {
            var obj = {
                "title": $(".main h1.title").text(),
                "link": this.href
            }
            $(".pdflink.customLink").parent().parent().append('<li>\
                <a href="javascript:_ebscoSaveToCloud(\'' + encodeURIComponent(JSON.stringify(obj)) + '\',1)"\
                >\
                    Save PDF to Cloud\
                </a>\
            </li>');
        });
    });
    
    //reference https://stackoverflow.com/questions/4565112/javascript-how-to-find-out-if-the-user-browser-is-chrome/13348618#13348618
    function isChrome() {
        var isChromium = window.chrome,
        winNav = window.navigator,
        vendorName = winNav.vendor,
        isOpera = winNav.userAgent.indexOf("OPR") > -1,
        isIEedge = winNav.userAgent.indexOf("Edge") > -1,
        isIOSChrome = winNav.userAgent.match("CriOS");
    
        if (isIOSChrome) {
        return true;
        } else if (
        isChromium !== null &&
        typeof isChromium !== "undefined" &&
        vendorName === "Google Inc." &&
        isOpera === false &&
        isIEedge === false
        ) {
        return true;
        } else {
        return false;
        }
    }

    function _ebscoSaveToCloud(obj, DR){

        function proc(url, title){
            if (url == "javascript:LoginRequired();"){
                return;
            }
            var s2c = "https://widgets.ebscohost.com/prod/customlink/savetocloud/?q=" + encodeURIComponent(url) + "&title=" + title

            // Chrome doesn't like not opening on http
            if(document.location.protocol != "https:" && isChrome()){
                var s2cw=550;
                var s2ch=350;
                var s2cleft = screen.availLeft + (screen.width/2)-(s2cw/2);
                var s2ctop = screen.availTop + (screen.height/2)-(s2ch/2);
                save2cloudWindow = window.open(s2c,'save2cloud',"");
                // save2cloudWindow.moveTo(s2cleft, s2ctop);
                // save2cloudWindow.focus();   
                if(!save2cloudWindow || save2cloudWindow.closed || typeof save2cloudWindow.closed=='undefined') { 
                    alert("Pop-up was blocked! Please add this site to your exception list.");
                } else {
                    save2cloudWindow.focus();  
                }
            }else{
                LightboxOpen(s2c, '550', '290');
            }
        }

        obj = JSON.parse(decodeURIComponent(obj));

        if (!DR){
            jQuery.ajax({
                "url": obj.link
            }).done(function(data) {
                var url = $(data).find(".pdflink.customLink")[0].href.replace("http","https");
                proc(url, obj.title);
            });
        } else {
            proc(obj.link, obj.title);
        }
    }

    window._ebscoSaveToCloud = _ebscoSaveToCloud;

})();