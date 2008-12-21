// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function progressPercent(bar, percentage) {
  document.getElementById(bar).style.width =  parseInt(percentage*2)+"px";
  document.getElementById(bar).innerHTML= "<div align='center'>"+percentage+"%</div>"
}

function updateStatus(status, c, rc, t)
{
    alert('updateStatus!')
    var statusHTML;
    var progressBarWidth;

    if(status == 'initializing') {
        $('statusProgressBar').setStyle({ width: '0px' });
        statusHTML = '<span id="top">Initializing...</span>';
    } else if(status == 'canceled') {
        $('statusProgressBar').setStyle({ width: '0px' });
        statusHTML = '<span id="top">Canceled... '+number_format(c / t * 100, 2)+'% Complete</span>';
    } else {
        if(t) {
            statusHTML = '<span id="top">'+rc+' result(s) ('+number_format((c ? (rc / c) : 0) * 100, 2)+'%)</span><br/><span id="bot">'+c+' of '+t+' processed ('+number_format(c / t * 100, 2)+'%)</span>';
        } else {
            statusHTML = '<span id="top">0 result(s)</span>';
        }
        progressBarWidth = Math.floor(675 * (c / t));
        $('statusProgressBar').setStyle({ width: progressBarWidth+'px' });
    }
    $('statusProgress').update(statusHTML);
}

function number_format( number, decimals, dec_point, thousands_sep ) {
    // http://kevin.vanzonneveld.net
    // +   original by: Jonas Raoni Soares Silva (http://www.jsfromhell.com)
    // +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
    // +     bugfix by: Michael White (http://getsprink.com)
    // +     bugfix by: Benjamin Lupton
    // +     bugfix by: Allan Jensen (http://www.winternet.no)
    // +    revised by: Jonas Raoni Soares Silva (http://www.jsfromhell.com)
    // +     bugfix by: Howard Yeend
    // *     example 1: number_format(1234.5678, 2, '.', '');
    // *     returns 1: 1234.57

    var n = number, c = isNaN(decimals = Math.abs(decimals)) ? 2 : decimals;
    var d = dec_point == undefined ? "." : dec_point;
    var t = thousands_sep == undefined ? "," : thousands_sep, s = n < 0 ? "-" : "";
    var i = parseInt(n = Math.abs(+n || 0).toFixed(c)) + "", j = (j = i.length) > 3 ? j % 3 : 0;

    return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
}
