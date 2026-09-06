import nh3

_BASE_TAGS = {
    "p", "br", "strong", "em", "u", "ul", "ol", "li", "a",
    "h2", "h3", "h4", "blockquote", "table", "thead", "tbody", "tr", "th", "td",
}
# No "rel": nh3 manages it and rejects the tag being in both places. It stamps
# rel="noopener noreferrer" on every link, which is what target="_blank" needs.
_BASE_ATTRIBUTES = {"a": {"href", "title", "target"}}
_IMG_ATTRIBUTES = {"img": {"src", "alt", "width", "height"}}


def clean_html(html, *, allow_images=False):
    """Strip everything but the tags our editors are allowed to produce.

    `allow_images` exists for product bodies, where staff insert images through
    the TinyMCE upload flow; article bodies stay image-free as before. nh3 drops
    unsafe URL schemes (javascript:, data:) on its own.
    """
    tags = set(_BASE_TAGS)
    attributes = dict(_BASE_ATTRIBUTES)
    if allow_images:
        tags.add("img")
        attributes.update(_IMG_ATTRIBUTES)
    return nh3.clean(html or "", tags=tags, attributes=attributes)
