package com.wingai.keyboard.data

import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.inputmethod.ExtractedTextRequest
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputMethodManager
import com.wingai.keyboard.privacy.PrivacyGuard
import helium314.keyboard.latin.LatinIME
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.lang.ref.WeakReference

object InputConnectionBridge {
    @Volatile
    private var imeServiceRef: WeakReference<InputMethodService>? = null

    @Volatile
    private var connectionProvider: (() -> InputConnection?)? = null

    @Volatile
    private var activeInputType: Int = 0

    @Volatile
    private var collapsedForSelection: Boolean = false

    private val mainHandler = Handler(Looper.getMainLooper())

    private val _sessionState = MutableStateFlow(AiSessionState())
    val sessionState: StateFlow<AiSessionState> = _sessionState.asStateFlow()

    fun isCollapsedForSelection(): Boolean = collapsedForSelection

    @JvmOverloads
    fun bindInputMethod(
        imeService: InputMethodService? = null,
        provider: () -> InputConnection?,
        inputType: Int
    ) {
        if (imeService != null) {
            imeServiceRef = WeakReference(imeService)
        }
        connectionProvider = provider
        activeInputType = inputType
        _sessionState.update { it.copy(isKeyboardVisible = true) }
    }

    fun unbindInputMethod() {
        _sessionState.update {
            it.copy(
                isKeyboardVisible = false,
                activeInputTarget = ActiveInputTarget.HOST_APP
            )
        }
    }

    /**
     * Collapses the keyboard's visible insets to 0px without calling requestHideSelf(0),
     * so the underlying chat app expands to full screen height while keeping the IME bound
     * and the text field focused.
     */
    fun hideKeyboardForSelection() {
        collapsedForSelection = true
        mainHandler.post {
            runCatching {
                val ime = imeServiceRef?.get()
                if (ime is LatinIME) {
                    ime.setSelectionCollapseMode(true)
                } else {
                    ime?.requestHideSelf(0)
                }
            }
        }
    }

    /**
     * Restores the keyboard's full height and visibility immediately when selection finishes
     * or is canceled.
     */
    fun restoreKeyboardAfterSelection() {
        collapsedForSelection = false
        val delays = longArrayOf(0L, 100L, 260L)
        for (delayMs in delays) {
            mainHandler.postDelayed({
                collapsedForSelection = false
                val ime = imeServiceRef?.get() ?: return@postDelayed
                runCatching {
                    if (ime is LatinIME) {
                        ime.setSelectionCollapseMode(false)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        ime.requestShowSelf(InputMethodManager.SHOW_IMPLICIT)
                    }
                }
            }, delayMs)
        }
    }

    fun isPasswordFieldActive(): Boolean = PrivacyGuard.isPasswordInputType(activeInputType)

    fun hasActiveInputConnection(): Boolean = connectionProvider?.invoke() != null

    fun consumeHostFieldTextAsPrompt(): String {
        if (isPasswordFieldActive()) return ""
        val ic = connectionProvider?.invoke() ?: return ""
        val extracted = ic.getExtractedText(ExtractedTextRequest(), 0)?.text?.toString()?.trim()
            ?: ic.getTextBeforeCursor(250, 0)?.toString()?.trim()
            ?: ""
        if (extracted.isNotBlank()) {
            ic.deleteSurroundingText(extracted.length + 10, 10)
            _sessionState.update { it.copy(customInstruction = extracted) }
        }
        return extracted
    }

    fun insertReply(text: String): Result<Unit> {
        val ic = connectionProvider?.invoke()
            ?: return Result.failure(IllegalStateException("Select a text field before inserting a reply."))
        if (isPasswordFieldActive()) {
            return Result.failure(IllegalStateException("WingAI is disabled in password fields."))
        }
        // Commit the reply text without sending or submitting the form (AT-08, AT-09).
        val committed = ic.commitText(text, 1)
        return if (committed) {
            _sessionState.update {
                it.copy(
                    preservedDraft = text,
                    errorMessage = null,
                    isPanelOpen = false,
                    activeInputTarget = ActiveInputTarget.HOST_APP
                )
            }
            Result.success(Unit)
        } else {
            Result.failure(IllegalStateException("Select a text field before inserting a reply."))
        }
    }

    fun updateState(transform: (AiSessionState) -> AiSessionState) {
        _sessionState.update(transform)
    }

    fun clearContext() {
        _sessionState.update { current ->
            AiSessionState(
                isPanelOpen = current.isPanelOpen,
                isKeyboardVisible = current.isKeyboardVisible,
                preservedDraft = current.preservedDraft,
                userProfile = current.userProfile
            )
        }
    }
}
