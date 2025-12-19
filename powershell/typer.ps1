
<#
.SYNOPSIS
Displays a persistent custom pop-up input form. Gets text via button click,
escapes special characters, and then types the text into the currently
focused window using SendKeys character-by-character. Uses WScript.Shell
for '{' workaround.
.DESCRIPTION
Uses Windows Forms for a persistent, non-modal input window. An event handler
on the OK button captures text. The main script loop processes events to keep
the form responsive between sends. When text is submitted, it loops through
the input character by character. A switch statement determines the correct
SendKeys sequence (e.g., '{' becomes '{{}', '(' becomes '{(}', 'a' remains 'a').
After a delay for manual window focusing, it sends the determined sequences
individually, using WScript.Shell for '{' and SendKeys.SendWait for others.
The form remains open for reuse until closed or Cancel is clicked.
THIS IS REQUIRED WHEN CLIPBOARD SHARING TO THE TARGET IS DISABLED.
.NOTES
Requires .NET Framework.
Relies on SendKeys methods, which are fragile (focus dependent).
Character-by-character sending is reliable but can be slow.
Uses WScript.Shell COM object - ensure permissions allow this.
Adjust $delayBetweenKeys for speed vs reliability.
The form WILL become unresponsive during the slow sending process.
Uses Application.DoEvents() which can have complexities in edge cases.
#>

# Add necessary .NET assemblies for WinForms and SendKeys
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}
catch {
    Write-Error "Failed to load required assemblies. Ensure .NET Framework is properly installed."
    exit 1
}
# --- Configuration ---
$script:promptMessage    = "Enter/paste text below. Click OK to send. It will be TYPED SLOWLY into the ACTIVE window after the delay. (Clipboard Disabled)."
$script:windowTitle      = "Type Text via SendKeys (Persistent Form)"
$script:defaultText      = ""
$script:delayBeforeSend  = 5   # Seconds to wait AFTER clicking OK for focusing the target window
$script:delayBetweenKeys = 75  # Milliseconds to pause between sending EACH key/sequence (ADJUST FOR SPEED VS RELIABILITY)
# --- Global Variables for State ---
$script:textToSend = $null
$script:newInputAvailable = $false
$script:exitLoop = $false
# --- Create Form Elements (Define at script scope) ---
$script:form = New-Object System.Windows.Forms.Form
$script:label = New-Object System.Windows.Forms.Label
$script:textBox = New-Object System.Windows.Forms.TextBox
$script:okButton = New-Object System.Windows.Forms.Button
$script:cancelButton = New-Object System.Windows.Forms.Button
# Configure Form
$script:form.Text = $script:windowTitle
$script:form.Size = New-Object System.Drawing.Size(450, 350)
$script:form.MinimumSize = New-Object System.Drawing.Size(300, 200)
$script:form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
# $script:form.TopMost = $true # Maybe not desirable for a persistent tool
# Configure Label
$script:label.Location = New-Object System.Drawing.Point(10, 10)
$script:label.Size = New-Object System.Drawing.Size(410, 20)
$script:label.Text = $script:promptMessage
$script:form.Controls.Add($script:label)
# Configure TextBox
$script:textBox.Location = New-Object System.Drawing.Point(10, 35)
$script:textBox.Size = New-Object System.Drawing.Size(410, 220)
$script:textBox.Multiline = $true
$script:textBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$script:textBox.AcceptsReturn = $true
$script:textBox.Text = $script:defaultText
$script:textBox.Anchor = [System.Windows.Forms.AnchorStyles] 'Top, Bottom, Left, Right'
$script:form.Controls.Add($script:textBox)
# Configure OK Button
$script:okButton.Location = New-Object System.Drawing.Point(250, 270)
$script:okButton.Size = New-Object System.Drawing.Size(80, 25)
$script:okButton.Text = "OK"
# $script:okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK # Not needed for non-modal
$script:okButton.Anchor = [System.Windows.Forms.AnchorStyles] 'Bottom, Right'
$script:form.AcceptButton = $script:okButton
$script:form.Controls.Add($script:okButton)
# Configure Cancel Button
$script:cancelButton.Location = New-Object System.Drawing.Point(340, 270)
$script:cancelButton.Size = New-Object System.Drawing.Size(80, 25)
$script:cancelButton.Text = "Cancel"
# $script:cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel # Not needed directly, use FormClosing
$script:cancelButton.Anchor = [System.Windows.Forms.AnchorStyles] 'Bottom, Right'
$script:form.CancelButton = $script:cancelButton # Still allows ESC to trigger it
$script:form.Controls.Add($script:cancelButton)
# --- Event Handlers ---
# OK Button Click Handler
$okButton_OnClick = {
    Write-Host "`nOK clicked. Capturing text..." -ForegroundColor Green
    $script:textToSend = $script:textBox.Text
    $script:newInputAvailable = $true
    # Optionally clear the textbox for the next input
    # $script:textBox.Text = ""
    # Optionally disable OK button while sending? Could add complexity.
}
# Form Closing Handler (Handles Cancel button click via CancelButton property, and 'X' button)
$form_FormClosing = {
    # Param($sender, $e) # Optional event arguments
    Write-Host "`nClose requested. Exiting script." -ForegroundColor Yellow
    $script:exitLoop = $true
    # No need to explicitly call $form.Close() here, it's already happening.
    # $script:form.Dispose() # Dispose might happen automatically, or do it after loop
}
# Register Event Handlers
$script:okButton.Add_Click($okButton_OnClick)
$script:form.Add_FormClosing($form_FormClosing)

# --- Prepare WScript.Shell ---
try {
    $script:wshell = New-Object -ComObject WScript.Shell
} catch {
    Write-Error "Failed to create WScript.Shell COM object. Ensure COM is available/permissions are correct."
    exit 1 # Exit if COM object fails
}
# --- Show Form Non-Modally ---
Write-Host "Displaying persistent input form. Close the form or click Cancel to exit script." -ForegroundColor Cyan
$script:form.Show()

# --- Main Event Loop ---
while (-not $script:exitLoop) {
    # Check if new input was submitted via OK button
    if ($script:newInputAvailable) {
        # Reset flag
        $script:newInputAvailable = $false
        $currentInput = $script:textToSend # Get the text captured by the event handler
        $script:textToSend = $null # Clear captured text
        if ($currentInput -ne $null) { # Check if text is actually present
            Write-Host "`nText received ($($currentInput.Length) characters). Preparing to send..." -ForegroundColor Green
            Write-Host "-------------------------------------"
            # Prompt user to focus the target window manually.
            Write-Warning -Message "IMPORTANT: Click on the window AND FIELD where you want the text typed NOW! Form will be unresponsive during sending."
            Write-Host "Sending keystrokes in $script:delayBeforeSend seconds..."
            Start-Sleep -Seconds $script:delayBeforeSend
            # --- Send CHARACTER BY CHARACTER using SWITCH statement ---
            Write-Host "Sending keys CHARACTER BY CHARACTER (Switch Logic - this will be slow)..." -ForegroundColor Magenta
            $sequencesSentCount = 0 # Count individual characters/sequences sent
            $errorOccurred = $false # Flag for error tracking
            $sequenceToSend = "" # Variable to hold the sequence being attempted
            # Loop through the CURRENT input string
            for ($i = 0; $i -lt $currentInput.Length; $i++) {
                $char = $currentInput[$i]
                $sequenceToSend = "" # Reset for this character
                # Determine the correct SendKeys sequence for the current character
                switch ($char) {
                    '{' { $sequenceToSend = '{{}' }
                    '}' { $sequenceToSend = '{}}' }
                    '(' { $sequenceToSend = '{(}' }
                    ')' { $sequenceToSend = '{)}' }
                    '^' { $sequenceToSend = '{^}' }
                    '+' { $sequenceToSend = '{+}' }
                    '%' { $sequenceToSend = '{%}' }
                    '~' { $sequenceToSend = '{~}' }
                    # Handle newline characters explicitly if needed (SendKeys uses ~ or {ENTER})
                    # "`n" { $sequenceToSend = '{ENTER}'; break } # Example for LF -> Enter
                    # "`r" { continue } # Example: Skip CR if handling LF
                    default { $sequenceToSend = $char } # Send other chars directly
                }
                # Now send the determined sequence using the hybrid method
                try {
                    if ($sequenceToSend -eq '{{}') {
                        $script:wshell.SendKeys($sequenceToSend)
                    } else {
                        [System.Windows.Forms.SendKeys]::SendWait($sequenceToSend)
                    }
                    $sequencesSentCount++
                    Start-Sleep -Milliseconds $script:delayBetweenKeys
                } catch {
                    Write-Error "An error occurred trying to send keystrokes (processing character '$char' at index $i): $($_.Exception.Message)"
                    Write-Host "DEBUG: Failed trying to send sequence: [$sequenceToSend]" -ForegroundColor Red
                    $errorOccurred = $true
                    break # Exit the for loop on error
                }
            } # End for loop
            # Display result message
            if (-not $errorOccurred) {
                Write-Host "`nKeystrokes sent successfully ($sequencesSentCount individual key sequences)." -ForegroundColor Green
            } else {
                 Write-Host "`nKeystroke sending stopped due to error." -ForegroundColor Red
            }
            Write-Host "-------------------------------------"
            Write-Host "Form is ready for next input." -ForegroundColor Cyan
            # --- End Character-by-Character Sending ---
        } else {
             Write-Host "`nOK clicked, but input text was empty. No keys sent." -ForegroundColor Yellow
        }
    } # End if ($script:newInputAvailable)
    # Process Windows messages to keep the form responsive
    [System.Windows.Forms.Application]::DoEvents()
    # Pause briefly to prevent high CPU usage
    Start-Sleep -Milliseconds 100
} # End main while loop
# --- Clean up ---
# Form might already be disposed by FormClosing, but check just in case
if ($script:form -ne $null -and -not $script:form.IsDisposed) {
    $script:form.Dispose()
}
Write-Host "`nScript finished."
# --- Important Security Note ---
# (Warnings remain the same, plus unresponsiveness note)
Write-Warning @"
Using SendKeys for automation is fragile:
1. Focus Dependency: Keystrokes are sent to whichever window/field is active.
2. Timing Issues: '$delayBetweenKeys' may need adjustment.
3. Speed: Sending text this way is VERY SLOW.
4. Unresponsiveness: The input form WILL FREEZE while keys are being sent.
5. Special Characters: Test thoroughly.
"@
