package com.example.gateway

/**
 * ASCII ISO-8583 test codec. It builds a primary bitmap and validates common
 * financial fields. A certified bank profile must supply any private/BCD/binary
 * rules before this codec is connected to a live switch.
 */
class Iso8583Codec {
    private data class Spec(val length: Int, val variable: Boolean = false, val numeric: Boolean = false)
    private val specs = mapOf(2 to Spec(19, true, true), 3 to Spec(6, numeric = true), 4 to Spec(12, numeric = true), 7 to Spec(10, numeric = true), 11 to Spec(6, numeric = true), 12 to Spec(6, numeric = true), 13 to Spec(4, numeric = true), 18 to Spec(4, numeric = true), 22 to Spec(3, numeric = true), 32 to Spec(11, true, true), 37 to Spec(12), 38 to Spec(6), 39 to Spec(2), 41 to Spec(8), 42 to Spec(15), 43 to Spec(40), 49 to Spec(3, numeric = true), 55 to Spec(255, true), 90 to Spec(42, numeric = true))

    fun pack(mti: String, fields: Map<Int, String>): ByteArray {
        require(mti.matches(Regex("\\d{4}"))) { "MTI must contain four digits" }
        require(fields.keys.all { it in 2..64 && specs.containsKey(it) }) { "Profile contains unsupported ISO field" }
        val bitmap = ByteArray(8)
        fields.keys.sorted().forEach { field -> val index = field - 1; bitmap[index / 8] = (bitmap[index / 8].toInt() or (1 shl (7 - (index % 8)))).toByte() }
        val body = fields.keys.sorted().joinToString("") { field -> encodeField(field, fields.getValue(field)) }
        return (mti + bitmap.joinToString("") { "%02X".format(it) } + body).toByteArray(Charsets.US_ASCII)
    }

    fun unpack(message: ByteArray): Pair<String, Map<Int, String>> {
        val text = message.toString(Charsets.US_ASCII); require(text.length >= 20) { "ISO message is too short" }
        val mti = text.substring(0, 4); require(mti.matches(Regex("\\d{4}"))) { "Invalid MTI" }
        val bitmap = (0 until 8).map { text.substring(4 + it * 2, 6 + it * 2).toInt(16) }
        var offset = 20; val fields = linkedMapOf<Int, String>()
        for (field in 2..64) if ((bitmap[(field - 1) / 8] and (1 shl (7 - ((field - 1) % 8)))) != 0) {
            val spec = specs[field] ?: throw IllegalArgumentException("No field rule for DE$field")
            val length = if (spec.variable) { val prefix = text.substring(offset, offset + 2).toInt(); offset += 2; prefix } else spec.length
            require(length <= spec.length && offset + length <= text.length) { "Invalid DE$field length" }
            fields[field] = text.substring(offset, offset + length); offset += length
        }
        require(offset == text.length) { "Unexpected bytes after ISO message" }
        return mti to fields
    }

    private fun encodeField(field: Int, value: String): String {
        val spec = specs.getValue(field); require(value.length <= spec.length && value.isNotBlank()) { "Invalid DE$field length" }
        if (spec.numeric) require(value.all(Char::isDigit)) { "DE$field must be numeric" }
        return if (spec.variable) value.length.toString().padStart(2, '0') + value else value.padStart(spec.length, if (spec.numeric) '0' else ' ')
    }
}
