/*
 * Dialog Url JavaScript code
 */
(function () {
  var dialogUrl = {
    makeDialogUrl: function (url, args) {
      args = args || []

      // replace unicode escapes
      url = url.replace(/\\u(\d\d\d\d)/g, function (m, d) {
        return String.fromCharCode(parseInt(d, 16))
      })
      // Parameters are added to the URL as <p1>, <p2>, ... (case insensitive)
      // %3C is <, %3E is >
      for (let i = 1; i <= args.length; i++) {
        const p = 'p' + i
        url = url.replace('%3C' + p + '%3E', encodeURIComponent(args[i - 1]))
        url = url.replace('%3C' + p.toUpperCase() + '%3E', encodeURIComponent(args[i - 1]))
      }
      return url
    }
  }
  window.dialogUrl = dialogUrl
})(apex.jQuery)
