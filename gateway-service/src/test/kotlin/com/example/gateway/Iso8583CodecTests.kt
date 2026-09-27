package com.example.gateway

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class Iso8583CodecTests {
    @Test fun `packs and unpacks a common purchase request`() {
        val codec = Iso8583Codec()
        val packed = codec.pack("0200", mapOf(3 to "000000", 4 to "000000001500", 11 to "123456", 41 to "TERM0001", 42 to "MERCHANT0000001", 49 to "971"))
        val decoded = codec.unpack(packed)
        assertEquals("0200", decoded.first)
        assertEquals("000000001500", decoded.second[4])
        assertEquals("TERM0001", decoded.second[41])
    }
}
