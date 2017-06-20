    var script = document.createElement('script');
    script.setAttribute('class', 'edsautocomplete-app');
    script.setAttribute('data-a', '');
    script.setAttribute('data-q', 'search?query-1=AND,{searchterm}*&view=title&resultsperpage=5');
    script.setAttribute('data-s', '%23translControl1,%23searchsubmit,3,3,0,,0');
    script.type = 'text/javascript';
    script.src = 'https://widgets.ebscohost.com/prod/encryptedkey/edsautocomplete/edsautocomplete.js';
    document.body.appendChild(script);