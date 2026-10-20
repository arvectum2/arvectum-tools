package ru.arvectum.tools.tosize

import androidx.compose.ui.geometry.Offset
import org.junit.Assert.assertEquals
import org.junit.Test
import ru.arvectum.tools.tosize.ui.calculateNormalizedCrop
import ru.arvectum.tools.tosize.ui.DecimalFileSize
import ru.arvectum.tools.tosize.ui.decimalFileSize

class FormatBytesTest {
    @Test
    fun calculatesKilobytesUsingDecimalUnits() {
        assertEquals(DecimalFileSize(true, 500.0), decimalFileSize(500_000L))
    }

    @Test
    fun calculatesWholeMegabytesWithoutDecimals() {
        assertEquals(DecimalFileSize(false, 5.0), decimalFileSize(5_000_000L))
    }

    @Test
    fun calculatesFractionalMegabytesWithoutPrematureRounding() {
        assertEquals(DecimalFileSize(false, 4.73), decimalFileSize(4_730_000L))
    }

    @Test
    fun calculatesLandscapeLongSideAndPreservesRatio() {
        assertEquals(
            ImageDimensions(width = 600, height = 270),
            calculateLongSideDimensions(
                width = 6560,
                height = 2952,
                targetLongSide = 600,
            ),
        )
    }

    @Test
    fun calculatesPortraitLongSideAndPreservesRatio() {
        assertEquals(
            ImageDimensions(width = 270, height = 600),
            calculateLongSideDimensions(
                width = 2952,
                height = 6560,
                targetLongSide = 600,
            ),
        )
    }

    @Test
    fun centeredPassportCropUsesFullHeightForWideImage() {
        val crop = calculateNormalizedCrop(
            bitmapWidth = 1000,
            bitmapHeight = 1000,
            viewportWidth = 620,
            viewportHeight = 797,
            zoom = 1f,
            offset = Offset.Zero,
        )

        assertEquals(0f, crop.top, 0.001f)
        assertEquals(1f, crop.bottom, 0.001f)
        assertEquals(0.111f, crop.left, 0.002f)
        assertEquals(0.889f, crop.right, 0.002f)
    }
}
