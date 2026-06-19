package com.example.liquid_calendar

import android.content.Context
import android.graphics.RenderEffect
import android.graphics.Shader
import android.os.Build
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.platform.PlatformView

class LiquidGlassPlatformView(
    context: Context,
    private val viewId: Int,
    private val params: Map<*, *>
) : PlatformView {

    private val container = FrameLayout(context)

    init {
        val blurAmount = (params["blurAmount"] as? Double)?.toFloat() ?: 25f

        // Создаём полупрозрачный контейнер с blur эффектом
        container.setBackgroundColor(0x10FFFFFF.toInt())

        // Применяем RenderEffect blur на Android 12+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val blurEffect = RenderEffect.createBlurEffect(
                blurAmount, blurAmount, Shader.TileMode.CLAMP
            )
            container.setRenderEffect(blurEffect)
        }

        // Добавляем лёгкую окантовку
        val borderView = View(context)
        borderView.background = android.graphics.drawable.GradientDrawable().apply {
            shape = android.graphics.drawable.GradientDrawable.RECTANGLE
            cornerRadius = 40f
            setStroke(2, 0x30FFFFFF.toInt())
        }
        container.addView(borderView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))
    }

    override fun getView(): View = container

    override fun dispose() {}
}
