
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

!(function () {
    let lastDropdown;
    document.addEventListener("click", (event) => {
        if (
            event.target &&
            (event.target.classList.contains("dropdown") ||
                event.target.closest(".dropdown"))
        ) {
            return;
        }
        if (lastDropdown) {
            lastDropdown.classList.remove("dropdown-active");
            lastDropdown = null;
        }
    });
    document.querySelectorAll(".dropdown .dropdown-toggle").forEach((el) => {
        const dropdown = el.closest(".dropdown");
        el.addEventListener("click", () => {
            if (lastDropdown == dropdown) {
                dropdown.classList.remove("dropdown-active");
                lastDropdown = null;
            } else {
                if (lastDropdown) {
                    lastDropdown.classList.remove("dropdown-active");
                }
                lastDropdown = dropdown;
                dropdown.classList.add("dropdown-active");
            }
        });
    });
})();

!(function () {
    const postBtn = document.querySelector(".post-btn");
    const uploadForm = document.querySelector(".upload-form");
    const fileInput = uploadForm.querySelector('input[type="file"]');
    postBtn.addEventListener("click", (el) => {
        fileInput.click();
    });
    fileInput.addEventListener("change", () => {
        if (fileInput.files.length > 0) {
            uploadForm.submit();
        }
    });
})();

!(function () {
    const spacing = 10; // 10px

    document.querySelectorAll(".carousel").forEach((el) => {
        const indicators = el.parentElement.querySelector(".carousel-indicators");
        if (!indicators) {
            return;
        }

        let previousActiveItem = 0;
        let lastTimeout = 0;

        el.addEventListener("scroll", () => {
            const currentItem = Math.round(
                (el.scrollLeft + spacing) / (el.clientWidth + spacing)
            );

            // debouncing
            clearTimeout(lastTimeout);
            lastTimeout = setTimeout(() => {
                el.scrollTo({
                    behavior: "smooth",
                    left: currentItem * spacing + currentItem * el.clientWidth,
                });
            }, 400);

            if (previousActiveItem !== currentItem) {
                indicators.children.item(previousActiveItem).classList.remove("active");
                previousActiveItem = currentItem;
                indicators.children.item(currentItem).classList.add("active");
            }
        });
    });
})();

async function copyLink(el, link) {
    await navigator.clipboard.writeText(link);
    el.innerText = "Copied!";
    setTimeout(() => {
        el.innerText = "Copy link"
    }, 2000)
}