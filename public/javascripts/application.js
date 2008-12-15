function popupWindowSmall(url) {
    window.open(url,
                "postEvent",
                "height=200,width=400,channelmode=0,dependent=0," +
                "directories=0,fullscreen=0,location=0,menubar=0," +
                "resizable=0,scrollbars=0,status=1,toolbar=0");
}
function popupWindowNarrow(url) {
    window.open(url,
                "listEvents",
                "height=600,width=400,channelmode=0,dependent=0," +
                "directories=0,fullscreen=0,location=0,menubar=0," +
                "resizable=0,scrollbars=1,status=1,toolbar=0");
}
function popupWindowWide(url) {
    window.open(url,
                "listEvents",
                "height=400,width=400,channelmode=0,dependent=0," +
                "directories=0,fullscreen=0,location=0,menubar=0," +
                "resizable=0,scrollbars=1,status=1,toolbar=0");
}

function deleterow(node)
{
// Obtain a reference to the containing tr. Use a while loop
// so the function can be called by passing any node contained by
// the tr node.
  var tr = node.parentNode;
  while (tr.tagName.toLowerCase() != "tr")
  tr = tr.parentNode;

  // Remove the tr node and all children.
  tr.parentNode.removeChild(tr);
}

function createCookie(name,value,days) {
        if (days) {
                var date = new Date();
                date.setTime(date.getTime()+(days*24*60*60*1000));
                var expires = "; expires="+date.toGMTString();
        }
        else var expires = "";
        document.cookie = name+"="+value+expires+"; path=/";
}

function eraseCookie(name) {
        createCookie(name,"",-1);
}

function readCookie(name) {
        var nameEQ = name + "=";
        var ca = document.cookie.split(';');
        for(var i=0;i < ca.length;i++) {
                var c = ca[i];
                while (c.charAt(0)==' ') c = c.substring(1,c.length);
                if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
        }
        return null;
}

function replace_plus(str) {
    words = str.split('+');
    return words.join(' ');
}

function mouseOver(imageName) {
    document[imageName].src=eval(imageName + 'H' ).src;
}

function mouseLeave(imageName) {
    document[imageName].src=eval(imageName + 'N' ).src;
}

function renderCookieBar() {
    if ( (amt = readCookie('_scamt')) == null )
        amt = '($0.00)';
    else
        amt = '($'+ amt + ')';

    if ( (count = readCookie('_sccount')) == null )
         count = '0 Items';
    else
        count = count + ' Items';

    if ((username = readCookie('username')) != null) {
        Element.update("username",  replace_plus(username));
        Element.show('username');
        Element.show('logout_button');
        Element.hide('login_button');
        $('account_button').removeClassName('black');
        $('account_button').addClassName('red');
    } else {
        Element.show('login_button');
        Element.hide('logout_button');
        Element.hide('username');
        $('account_button').removeClassName('red');
        $('account_button').addClassName('black');
    }
    Element.update("item_count", count);
    Element.update("sc_amount", amt);

    if (document.images) {
        sc_imageN = new Image(16,16);
        sc_imageN.src = '/images/Shoppingcart_16x16.png';
        sc_imageH = new Image(16,16);
        sc_imageH.src = '/images/Shoppingcart_alt_16x16.png';

        function mouseOver(imageName) {
            document[imageName].src=eval(imageName + 'H' ).src;
        }

        function mouseLeave(imageName) {
            document[imageName].src=eval(imageName + 'N' ).src;
        }
    }
}

/*
** Apparently we cannot disable a link (an 'a' element has no disable property) so we
** will grey it out and handing it downstream
*/
function disable_shipping_cart_link() {
    $('atc').removeClassName('red');
    $('atc').addClassName('grey');
}

function enable_shipping_cart_link() {
    $('atc').removeClassName('grey');
    $('atc').addClassName('red');
}


function renderNavbar() {
    if ((group = readCookie('group_focus')) != null )
        toggleVis(group);
}

function login() {
    var username = $F('name');
    var password = $F('password');
    var persist = $F('persist');
    var params = 'name='        + username +
                 '&password='   + password +
                 '&persist='    + persist  +
         '&authenticity_token=' + encodeURIComponent(window._token)

    new Ajax.Request('/sessions/login', { asynchronous:true, evalScripts:true, parameters:params} );
}

/*
** This are bill's functions
*/

function toggleVis(name)
{
    var item2;
    var item = document.getElementById(name);

    createCookie('group_focus', name, 1);

    if( item.style.display == "block") {
        item.style.display = "none";
        disable_shipping_cart_link();
    }
    else
        item2 = document.getElementById('led_menu_group');
        item2.style.display = "none";
        item2 = document.getElementById('scenery_menu_group');
        item2.style.display = "none";
        item2 = document.getElementById('vehicle_menu_group');
        item2.style.display = "none";
        item2 = document.getElementById('sequencer_menu_group');
        item2.style.display = "none";
        item2 = document.getElementById('control_menu_group');
        item2.style.display = "none";
        item.style.display = "block";
        enable_shipping_cart_link();
}

