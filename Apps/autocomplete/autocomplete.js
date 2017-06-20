    var script = document.createElement('script');
    script.setAttribute('class', 'edsautocomplete-app');
    script.setAttribute('data-a', 'https://widgets.ebscohost.com/prod/encryptedkey/eds/eds.php?k=eyJjdCI6ImpXeWF6K1BFWlc2QWlIMGVobGpwRWQzRUg2T0N4eFNxUUUxcVFVb0x2Tzg9IiwiaXYiOiI2ZmRiMDliN2I5MzMwMDMwZjMzYTBiZTU2NDkxYmVlMyIsInMiOiJlNjJiOWYxNTJiZjdhN2ZmIn0=&p=YWx2ZXRtLm1haW4uZWRzYXBp&s=0,1,1,0,0,0&q=');
    script.setAttribute('data-q', 'search?query-1=AND,{searchterm}*&view=title&resultsperpage=5');
    script.setAttribute('data-s', '%23translControl1,%23searchsubmit,3,3,0,,0');
    script.type = 'text/javascript';
    script.src = 'https://widgets.ebscohost.com/prod/encryptedkey/edsautocomplete/edsautocomplete.js';
    document.body.appendChild(script);