cordova.define('cordova/plugin_list', function(require, exports, module) {
module.exports = [
    {
        "file": "plugins/org.schoolsfirstfcu.mobile.plugin.checkcapture/www/Camera.js",
        "id": "org.schoolsfirstfcu.mobile.plugin.checkcapture.CheckCapture",
        "clobbers": [
            "navigator.checkcapture"
        ]
    }
]
});