package com.yona.app.core

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.jsonPrimitive

/**
 * Decodes a Postgres `numeric` that PostgREST may serialize as a JSON number OR a
 * string (to preserve precision). Mirrors the iOS flexible cost decode. Applied to
 * a nullable property, so kotlinx handles JSON null before this runs.
 */
object FlexibleDoubleSerializer : KSerializer<Double> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("FlexibleDouble", PrimitiveKind.DOUBLE)

    override fun deserialize(decoder: Decoder): Double {
        val jsonDecoder = decoder as? JsonDecoder ?: return decoder.decodeDouble()
        return jsonDecoder.decodeJsonElement().jsonPrimitive.content.toDouble()
    }

    override fun serialize(encoder: Encoder, value: Double) = encoder.encodeDouble(value)
}
