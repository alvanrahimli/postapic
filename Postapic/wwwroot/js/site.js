
document.querySelectorAll('[data-confirm]').forEach((el) => {
    function handler(event) {
        if (!confirm(el.getAttribute('data-confirm'))) {
            event.preventDefault();
            return false;
        }
    }

    switch (el.tagName) {
        case 'FORM':
            el.addEventListener('submit', handler);
            break;

        case 'A':
        case 'BUTTON':
            el.addEventListener('click', handler);
            break;
    }
});