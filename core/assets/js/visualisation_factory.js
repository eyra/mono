import { FileInputFactory } from "./file_input"
import { RadioInputFactory } from "./radio_input"

export const VisualisationFactory = (function() {
    'use strict';

    /* PUBLIC */

    function createComponent(data, locale) {
        const { type } = data

        if (mapping[type]) {
            const componentFactory = mapping[type]

            if (typeof componentFactory === 'function') {
                const componentData = data[type]
                return componentFactory(componentData, locale)
            } else {
                console.log("[VisualisationFactory] Component factory is not a function: ", type)
                return null
            }

        } else {
            console.log("[VisualisationFactory] Received unsupported prompt: ", type)
            return null
        }
    }

    /* PRIVATE */

    const mapping = {
        "file" : FileInputFactory,
        "radio" : RadioInputFactory
    }

    /* MODULE INTERFACE */

    return {
        createComponent
    }
})();