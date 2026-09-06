'use strict';

// Được khai báo theo tên trong TINYMCE_DEFAULT_CONFIG["images_upload_handler"]:
// init_tinymce.js của django-tinymce resolve chuỗi đó thành window[<tên>]
// trước khi gọi tinyMCE.init (xem danh sách `fns` trong file đó).
window.dalifoodsTinymceUpload = function (blobInfo) {
  function getCookie(name) {
    var match = document.cookie.match('(?:^|; )' + name + '=([^;]*)');
    return match ? decodeURIComponent(match[1]) : null;
  }

  var data = new FormData();
  data.append('file', blobInfo.blob(), blobInfo.filename());

  return fetch('/admin/tinymce-upload/', {
    method: 'POST',
    headers: { 'X-CSRFToken': getCookie('csrftoken') },
    body: data,
    credentials: 'same-origin',
  }).then(function (res) {
    if (!res.ok) {
      return res.json().catch(function () { return {}; }).then(function (body) {
        return Promise.reject(body.error || ('HTTP ' + res.status));
      });
    }
    return res.json().then(function (body) { return body.location; });
  });
};
