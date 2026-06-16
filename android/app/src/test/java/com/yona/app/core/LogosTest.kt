package com.yona.app.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LogosTest {

    @Test
    fun stripsWwwAndScheme() {
        assertEquals("netflix.com", Logos.domain("https://www.netflix.com/browse"))
    }

    @Test
    fun addsSchemeForBareDomain() {
        assertEquals("netflix.com", Logos.domain("netflix.com"))
    }

    @Test
    fun lowercasesHost() {
        assertEquals("apple.com", Logos.domain("HTTPS://Apple.com"))
    }

    @Test
    fun stripsPathQueryAndPort() {
        assertEquals("example.com", Logos.domain("http://example.com:8080/path?q=1#frag"))
    }

    @Test
    fun keepsSubdomains() {
        assertEquals("tv.apple.com", Logos.domain("https://tv.apple.com"))
    }

    @Test
    fun blankIsNull() {
        assertNull(Logos.domain("   "))
    }
}
