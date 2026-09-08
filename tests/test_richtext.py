from apps.common.richtext import clean_html


def test_script_and_event_handlers_are_stripped():
    dirty = '<p>Xin chào</p><script>alert(1)</script><a href="#" onclick="steal()">x</a>'
    cleaned = clean_html(dirty)
    assert "<script>" not in cleaned
    assert "onclick" not in cleaned
    assert "<p>Xin chào</p>" in cleaned


def test_none_body_becomes_empty_string():
    assert clean_html(None) == ""


def test_images_are_stripped_by_default():
    assert "<img" not in clean_html('<p>a</p><img src="/media/uploads/x.jpg" alt="x">')


def test_images_survive_when_allowed():
    cleaned = clean_html(
        '<img src="/media/uploads/x.jpg" alt="Ảnh" width="600" height="400">',
        allow_images=True,
    )
    assert 'src="/media/uploads/x.jpg"' in cleaned
    assert 'alt="Ảnh"' in cleaned
    assert 'width="600"' in cleaned


def test_data_uri_image_sources_do_not_survive():
    cleaned = clean_html('<img src="data:image/png;base64,AAAA" alt="x">', allow_images=True)
    assert "data:" not in cleaned
