
/**
 * Handle the user's intention when it checks the check mark
 * associated with this forwarding item.
 *
 * @param {Boolean} Value of check
*/
function checked (value) {
    if (value) {
        if (item.cachedRuleValue) {
            requestRule(item.cachedRuleValue);
        } else {
            d._editing = true;
        }
    } else {
        if (d._editing) {
            d._editing = false;
        } else {
            requestRule('');
        }
    }
}

/**
 * Request that the rule be changed on the backend.
 *
 * @param {String} new rule value
 * @return {Boolean} whether or not we requested a change
 */
function requestRule (value) {
    value = normalizePhoneNumber(value);
    if (value === item.callForwarding[item.rule]) {
        console.warn('Value did not change.');
        return false;
    }

    item.callForwarding[item.rule] = value;
    d._pending = true;
    return true;
}

/**
 * Handler for when the component enter or leaves editing mode.
 */
function editingChanged () {
     if (d._editing) {
        item.enteredEditMode();
     } else {
         item.leftEditMode();
     }
}

/**
 * Handler for when the rule changes on the backend.
 *
 * @param {String} the new property
 */
function ruleChanged (property) {
    check.checked = callForwarding[rule] !== "";
}

/**
 * Handler for when the backend responds.
 *
 * @param {Boolean} whether or not the backend succeeded
 */
function ruleComplete (success) {
    d._pending = false;
    d._editing = false;
    if (!success) {
        d._failed = true;
    }
}

/**
 * Handler for when the rule ready changes.
 */
function ruleReadyChanged () {
    d._pending = !callForwarding.ready;
}

/**
 * Scroll something into view.
 *
 * @param {QtObject} item to scroll to.
 */
function show(item) {
    if (!item) {
        return;
    }
    page.activeItem = item;

    var position = flick.contentItem.mapFromItem(item, 0, page.activeItem.y);

    // check if the item is already visible
    var bottomY = flick.contentY + flick.height;
    var itemBottom = position.y + item.height + units.gu(2); // extra margin
    if (position.y >= flick.contentY && itemBottom <= bottomY) {
        return;
    }

    // if it is not, try to scroll and make it visible
    var targetY = itemBottom - flick.height;
    if (targetY >= 0 && position.y) {
        flick.contentY = targetY;
    } else if (position.y < flick.contentY) {
        // if it is hidden at the top, also show it
        flick.contentY = position.y;
    }
    flick.returnToBounds();
}

/**
 * Normalizes a phone number.
 *
 * TODO(jgdx): Remove this and replace it with libphonenumber
 *
 * @param {String} number to normalize
 * @return {String} normalized number
 */
function normalizePhoneNumber(identifier) {
    var regexp = new RegExp('[()/-]', 'g');
    var finalNumber = identifier.replace(/\s+/g, '');
    finalNumber = finalNumber.replace(regexp, '');
    return finalNumber;
}
