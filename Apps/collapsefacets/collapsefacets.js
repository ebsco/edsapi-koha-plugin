jQuery('.eds-facet-label').each(function(){
    currentFacet = this;
    jQuery(currentFacet).click(function(){
        var currentClicked=this;
        var isCollapsed = jQuery(currentClicked).next().data('collapse');
        if(isCollapsed==1){
            jQuery(currentClicked).next().data('collapse','0');
            jQuery(currentClicked).next().css('display','block');
            var clickedText = jQuery(currentClicked).text();
            clickedText = '-'+clickedText.replace('+','');
            jQuery(currentClicked).text(clickedText);
        }else{
            jQuery(currentClicked).next().data('collapse','1');
            jQuery(currentClicked).next().css('display','none');
            var clickedText = jQuery(currentClicked).text();
            clickedText = '+'+clickedText.replace('-','');
            jQuery(currentClicked).text(clickedText);
        }
    });
});
jQuery('.eds-facet-label').trigger('click');
jQuery('.eds-facet-label').css('cursor','pointer');