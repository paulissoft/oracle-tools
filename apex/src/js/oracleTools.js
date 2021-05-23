// The Oracle tools namespace.
var oracleTools = {
	//	
	// Return the version of this namespace	.
	//
	version: function () {
		return '2020-12-16 13:05'; // yyy-mm-dd hh24:mi
	},

	//	
	// Set the active tab of a tab container.
	//	
  setActiveTab: function (tabsContainerId, tabId) {
    const href = '#SR_' + tabId
    const sessionStorage = apex.storage.getScopedSessionStorage({ usePageId: true, useAppId: true })

    // just cache the new region to go to but do not switch to it yet (too many screen changes)
    sessionStorage.setItem(tabsContainerId + '.activeTab', href)
  },

	//	
	// Get the activa tab of a tab container.
	//
  getActiveTab: function (tabsContainerId) {
    const sessionStorage = apex.storage.getScopedSessionStorage({ usePageId: true, useAppId: true })
    // just cache the new region to go to but do not switch to it yet (too many screen changes)
    const href = sessionStorage.getItem(tabsContainerId + '.activeTab')

    return href.slice(4)
  },

	//
	// Initialise a logger using the loglevel plugin.
	//
  initLogger: function () {
    const logger = log.noConflict()
    const prefixer = prefix.noConflict()

    prefixer.reg(logger)
    prefixer.apply(logger, { template: '[%t] %l (%n): ' })

    return logger
  },

	//	
  //  Remove the footer with number of records from an Interactive Grid configuration.
	//
  noFooterIG: function (config) {
    config.defaultGridViewOptions = {
      footer: false
    }
    return config
  },

	//	
  //  Turn an input field to initials capitalized like the Oracle function INITCAP.
	//
	//  Usage:
	//  * Javascript code:
	//   
	// 		$('input[id="FIRST_NAME"]').val (function () {
  //      return oracleTools.initCap(this.value)
	//    })
	//	
	//  * Affected Elements:
	//    - Selection Type: jQuery Selector
	//    -	jQuery Selector: .text_field
	//
  initCap: function (str) {
    var str1 = str.toLowerCase().split(' ').map(function (word) {
      // replace first letter of each word in a string separated by spaces (Jan Hendrik)
      return (word !== null && word.length > 0 ? word.replace(word[0], word[0].toUpperCase()) : word)
    }).join(' ')
    // Now separator "-": only convert first letter of each word to upper
    return str1.split('-').map(function (word) {
      // replace first letter of each word in a string separated by dashes (Gert-Jan)
      return (word !== null && word.length > 0 ? word.replace(word[0], word[0].toUpperCase()) : word)
    }).join('-')
  },

  //
  // Toggle view password.
  //
  // For a page item P2_PASSWORD use password as type and add a pre/post text like this:
  // <i id="PASSWORD_STATUS_P2_PASSWORD" class="fa fa-eye field-icon" aria-hidden="true" onClick="oracle_tools.toggleViewPassword('P2_PASSWORD')"></i>
  //
  // See also https://www.javainhand.com/2020/04/show-hide-password-mask-in-oracle-apex.html.
	//
  toggleViewPassword: function (item) {
    const passwordInput = document.getElementById(item)
    const passStatus = document.getElementById('PASSWORD_STATUS_' + item)

    if (passwordInput.type === 'password') {
      passwordInput.type = 'text'
      passStatus.className = 'fa fa-eye-slash field-icon'
    } else {
      passwordInput.type = 'password'
      passStatus.className = 'fa fa-eye field-icon'
    }
  },

	//
	// Initialise an Interactve Grid configuration.
	//
  initialiseIG: function (config, standardToolbar = false) {
    if (standardToolbar) {
      return config
    }

    // not a standard Toolbar: construct a minimal IG
    config.defaultGridViewOptions = {
      rowHeader: 'sequence'
    }

    config.toolbarData = [
      {
        align: 'end',
        controls: [
          {
            type: 'BUTTON',
            action: 'selection-add-row',
            // icon: 'icon-ig-add-row',
            iconBeforeLabel: true,
            hot: false
          },
          {
            type: 'BUTTON',
            action: 'save',
            // icon: 'icon-ig-save',
            iconBeforeLabel: true,
            hot: true
          },
					{
            type: "BUTTON",
            action: "reset-report",
            iconBeforeLabel: true
          }
        ]
      }
    ]

    return config
  }
}
