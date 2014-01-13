/*
 *	TypeWatch 2.0 - Original by Denny Ferrassoli / Refactored by Charles Christolini
 *
 *	Examples/Docs: www.dennydotnet.com
 *	
 *  Copyright(c) 2007 Denny Ferrassoli - DennyDotNet.com
 *  Coprright(c) 2008 Charles Christolini - BinaryPie.com
 *  
 *  Dual licensed under the MIT and GPL licenses:
 *  http://www.opensource.org/licenses/mit-license.php
 *  http://www.gnu.org/licenses/gpl.html
*/

new function($) {
  $.fn.setCursorPosition = function(pos) {
    if ($(this).get(0).setSelectionRange) {
      $(this).get(0).setSelectionRange(pos, pos);
    } else if ($(this).get(0).createTextRange) {
      var range = $(this).get(0).createTextRange();
      range.collapse(true);
      range.moveEnd('character', pos);
      range.moveStart('character', pos);
      range.select();
    }
  }
}(jQuery);

(function(jQuery) {
	jQuery.fn.typeWatch = function(o){
		// Options
		var options = jQuery.extend({
			wait : 750,
			callback : function() { },
			highlight : true,
			captureLength : 2
		}, o);
			
		function checkElement(timer, override) {
			var elTxt = jQuery(timer.el).val();
		
			// Fire if text > options.captureLength AND text != saved txt OR if override AND text > options.captureLength
			if ((elTxt.length > options.captureLength && elTxt.toUpperCase() != timer.text) 
			|| (override && elTxt.length > options.captureLength)) {
				timer.text = elTxt.toUpperCase();
				timer.cb(elTxt);
			}
		};
		
		function watchElement(elem) {			
			// Must be text or textarea
			if (elem.type.toUpperCase() == "TEXT" || elem.nodeName.toUpperCase() == "TEXTAREA") {

				// Allocate timer element
				var timer = {
					timer : null, 
					text : jQuery(elem).val().toUpperCase(),
					cb : options.callback, 
					el : elem, 
					wait : options.wait
				};

				// Set focus action (highlight)
				if (options.highlight) {
					jQuery(elem).focus(
						function() {
							this.select();
						});
				}

				// Key watcher / clear and reset the timer
				var startWatch = function(evt) {
					var timerWait = timer.wait;
					var overrideBool = false;
					
					if (evt.keyCode == 13 && this.type.toUpperCase() == "TEXT") {
						timerWait = 1;
						overrideBool = true;
					}
					
					var timerCallbackFx = function()
					{
						checkElement(timer, overrideBool)
					}
					
					// Clear timer					
					clearTimeout(timer.timer);
					timer.timer = setTimeout(timerCallbackFx, timerWait);				
										
				};
				
				jQuery(elem).keydown(startWatch);
			}
		};
		
		// Watch Each Element
		return this.each(function(index){
			watchElement(this);
		});
		
	};

})(jQuery);

/*

    My Social Dog JS
    (c) 2009

*/
var UpdateForm = {
    charLimit: 140,
    disabled: false,
    init: function()
    {
        $(document).ready(function(){
            if (true)
            {
                $('#update-button').mousedown(function(){
                    $(this).addClass('pressed');
                }).mouseup(function(){
                    $(this).removeClass('pressed');
                }).mouseout(function(){
                    $(this).removeClass('pressed');
                }).blur(function(){
                    $(this).removeClass('pressed');
                });
            }
            
            UpdateForm.initCounter();
            if (true)
            {
                UpdateForm.disable();
            }
            $('#update-body').focus();
        });
    },
    initCounter: function()
    {
        var opts = {
            callback: function(text){
                var uc  = $('#update-chars');
                var len = UpdateForm.charLimit - text.length;
                uc.html(len);
                if (len >= 140 || text == '')
                {
                    UpdateForm.disable();
                    uc.removeClass('warning');
                    uc.removeClass('over');
                }
                else if (len > 12)
                {
                    UpdateForm.enable();
                    uc.removeClass('warning');
                    uc.removeClass('over');
                }
                else if (len >= 0 && len <= 12)
                {
                    UpdateForm.enable();
                    uc.addClass('warning');
                    uc.removeClass('over');
                }
                else if (len < 0)
                {
                    UpdateForm.disable();
                    uc.removeClass('warning');
                    uc.addClass('over');
                }
            },
            wait: false,
            highlight: false,
            captureLength: -1
        }
        $('#update-body').typeWatch(opts);
    },
    enable: function()
    {
        if (UpdateForm.disabled)
        {
            var ub = $('#update-button');
            ub.attr('disabled', false);
            ub.removeClass('disabled');
            UpdateForm.disabled = false;
        }
    },
    disable: function()
    {
        if (!UpdateForm.disabled)
        {
            var ub = $('#update-button');
            ub.attr('disabled', true);
            ub.addClass('disabled');
            UpdateForm.disabled = true;
        }
    },
    chooseReplyTo: function()
    {
        $(document).ready(function(){
            var rt = $('#update-username');
            var u  = $('#update-body');
            u.val(u.val() + '@' + rt.val() + ' ').focus();
            u.setCursorPosition(u.val().length);
            UpdateForm.refresh();
            u.keydown();
        });
    },
    chooseHashTag: function()
    {
        $(document).ready(function(){
            var rt = $('#update-hashtag');
            var u  = $('#update-body');
            if (rt.val() != '')
            {
                var hshtag = ' #' + rt.val();
                u.val(u.val() + hshtag).focus();
                var tag_len = hshtag.length;
                u.setCursorPosition(u.val().length - tag_len);
                
                // Remove this option
                var selidx = rt.attr('selectedIndex');
                if (selidx > 0)
                {
                    $('#update-hashtag option[value=' + rt.val() + ']').remove();
                }
            }
            UpdateForm.refresh();
            u.keydown();
        });
    },
    refresh: function()
    {
        // TODO
        // update counter and update disabled/enabled state
    }
}

var Updates = {
    lastID: false,
    authToken: '',
    view: '',
    userID: false,
    zipcode: false,
    miles: false,
    loadMore: function(deprecated_last_id)
    {
        $('.load_more a').remove();
        $('.load_more').append('<a href="javascript:void(0);">Loading&hellip;</a>');
        $.post('/updates/render_stream',
        {
            ajax: true,
            view: Updates.view,
            last_id: Updates.lastID,
            authenticity_token: Updates.authToken,
            user_id: Updates.userID,
            zipcode: Updates.zipcode,
            miles: Updates.miles
        },
        function(data){
            $('.load_more').remove();
            $('#updates_updates_updates').append(data);
            $('div.update').removeClass('last');
            $('div.update:last').addClass('last');
        });
        
        return false;
    }
}

var Flashes = {
    clearFlashes: function()
    {
        $(document).ready(function(){
            setTimeout("$('.flash.notice, .flash.message').hide('normal')", 3500);
        });
    }
}

var Follows = {
    initFollowBy: function(auth_token)
    {
        $(document).ready(function(){
            $('input.updates-by').each(function(k, v){
                el = $(v);
                // Get values
                var user_id = $(v).attr('rel');
                var by      = $(v).hasClass('sms') ? 'sms' : 'email';
                // Watch clicks
                el.click(function(){
                    var enable = $(this).attr('checked') ? '1' : '0';
                    var params = {
                        authenticity_token: auth_token,
                        user_id: user_id,
                        by: by,
                        enable: enable
                    };
                    $.post('/follows/toggle_follow_by', params, function(){
                        // TODO flash or yellow fade
                    });
                });
            });
        });
    }
}

var BioFields = {
    initCounter: function()
    {
        var opts = {
            callback: function(text){
                var uc  = $('#update-chars');
                var len = UpdateForm.charLimit - text.length;
                uc.html(len + ' ' + (len == 1 ? 'character' : 'characters') + ' left');
                if (len >= 140 || text == '')
                {
                    uc.removeClass('warning');
                    uc.removeClass('over');
                }
                else if (len > 12)
                {
                    uc.removeClass('warning');
                    uc.removeClass('over');
                }
                else if (len >= 0 && len <= 12)
                {
                    uc.addClass('warning');
                    uc.removeClass('over');
                }
                else if (len < 0)
                {
                    uc.removeClass('warning');
                    uc.addClass('over');
                }
            },
            wait: false,
            highlight: false,
            captureLength: -1
        }
        $('#user_bio,#dog_bio').typeWatch(opts);
    }
}

var CharCounters = {
    /* Only for user fields presently */
    watchField: function(id, max_len)
    {
        var cnt_el = $('#update-chars-' + id);
        var el = $('#user_' + id);
        
        console.log(cnt_el, el);
        
        var opts = {
            callback: function(text){
                var uc  = cnt_el;
                var len = max_len - text.length;
                uc.html(len + ' ' + (len == 1 ? 'character' : 'characters') + ' left');
            },
            wait: false,
            highlight: false,
            captureLength: -1
        }
        el.typeWatch(opts);
    }
}

var Dog = {
    updateURLPreview: function(el)
    {
        $('#url_preview_dog').html(el.val().replace(/[^a-z0-9]/gi, '').toLowerCase());
    }
}

var FieldInfo = {
    extraPadding: 0,
    init: function()
    {
        // Watch anything with .field that also has msdcontext attr set
        var ctx = '';
        var fi  = null;
        $('.field').each(function(k, v){
            el  = $(v);
            ctx = el.attr('msd_context');
            if (ctx != null && ctx != '')
            {
                fi = $('#field_info');
                if (!el.hasClass('checkbox'))
                {
                    el.click(function(){
                        fi.html($(this).attr('msd_context')).show('fast');
                        FieldInfo.moveToField(fi, $(this));
                    });
                    el.focus(function(){
                        fi.html($(this).attr('msd_context')).show('fast');
                        FieldInfo.moveToField(fi, $(this));
                    });
                    el.blur(function(){
                        fi.html('').hide();
                    });
                }
            }
        });
    },
    moveToField: function(field_info, el, extra_padding)
    {
        if (extra_padding == null) extra_padding = 0;
        var off = el.offset();
        
        var ctop  = Math.floor(off.top) - FieldInfo.extraPadding;
        var cleft = el.width();
        
        $(field_info).css('top', ctop).css('left', cleft);
    },
    forField: function(id)
    {
        var el  = $('#' + id);
        var ctx = el.attr('msd_context');
        var fi  = $('#field_info');
        fi.html(ctx).show('fast');
        FieldInfo.moveToField(fi, el, 172);
        return false;
    }
}