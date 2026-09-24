package ru.arvectum.tools.tosize

import org.junit.Assert.assertEquals
import org.junit.Test
import ru.arvectum.tools.tosize.ui.formatBytes

class FormatBytesTest {
    @Test
    fun formatsKilobytesUsingDecimalUnits() {
        assertEquals("500 КБ", formatBytes(500_000L))
    }

    @Test
    fun formatsWholeMegabytesWithoutDecimals() {
        assertEquals("5 МБ", formatBytes(5_000_000L))
    }

    @Test
    fun formatsFractionalMegabytesWithTwoDecimals() {
        assertEquals("4,73 МБ", formatBytes(4_730_000L))
    }
}
