Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ===== 样式配置 =====
$theme = @{
    BgColor      = [System.Drawing.Color]::FromArgb(245, 246, 250)
    CardColor    = [System.Drawing.Color]::White
    PrimaryColor = [System.Drawing.Color]::FromArgb(74, 144, 226)
    SuccessColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
    WarningColor = [System.Drawing.Color]::FromArgb(241, 196, 15)
    DangerColor  = [System.Drawing.Color]::FromArgb(231, 76, 60)
    TextColor    = [System.Drawing.Color]::FromArgb(47, 53, 66)
    LogBg        = [System.Drawing.Color]::FromArgb(30, 30, 30)
    LogFg        = [System.Drawing.Color]::FromArgb(0, 255, 0)
}

$fontMain = New-Object System.Drawing.Font("Microsoft YaHei UI", 10)
$fontBold = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
$fontLargeBold = New-Object System.Drawing.Font("Microsoft YaHei UI", 14, [System.Drawing.FontStyle]::Bold)
$fontSmall = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)

$configFile = "$PSScriptRoot\config.txt"
$lastPath = if (Test-Path $configFile) { Get-Content $configFile | Select-Object -First 1 } else { "" }

# 任务状态变量
$global:isPaused = $false
$global:isStopped = $false

# ===== 文件冲突处理函数 =====
function Show-ConflictDialog($fileName) {
    $cForm = New-Object System.Windows.Forms.Form
    $cForm.Text = "文件已存在"
    $cForm.Size = "400, 260"
    $cForm.StartPosition = "CenterParent"
    $cForm.FormBorderStyle = "FixedDialog"
    $cForm.MaximizeBox = $false
    $cForm.MinimizeBox = $false
    $cForm.BackColor = [System.Drawing.Color]::White

    $lblMsg = New-Object System.Windows.Forms.Label
    $lblMsg.Text = "输出文件夹已存在文件:`n$fileName"
    $lblMsg.Font = $fontMain
    $lblMsg.Size = "360, 60"
    $lblMsg.Location = "20, 20"
    $cForm.Controls.Add($lblMsg)

    $btnOverwrite = New-Object System.Windows.Forms.Button
    $btnOverwrite.Text = "覆盖"
    $btnOverwrite.Size = "100, 35"
    $btnOverwrite.Location = "50, 90"
    $btnOverwrite.FlatStyle = "Flat"
    $btnOverwrite.BackColor = $theme.WarningColor
    $btnOverwrite.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $cForm.Controls.Add($btnOverwrite)

    $btnRename = New-Object System.Windows.Forms.Button
    $btnRename.Text = "重命名"
    $btnRename.Size = "100, 35"
    $btnRename.Location = "230, 90"
    $btnRename.FlatStyle = "Flat"
    $btnRename.BackColor = $theme.PrimaryColor
    $btnRename.ForeColor = [System.Drawing.Color]::White
    $btnRename.DialogResult = [System.Windows.Forms.DialogResult]::No
    $cForm.Controls.Add($btnRename)

    $chkAll = New-Object System.Windows.Forms.CheckBox
    $chkAll.Text = "对后续所有冲突文件执行相同操作"
    $chkAll.Location = "50, 150"
    $chkAll.Size = "300, 30"
    $chkAll.Checked = $true 
    $cForm.Controls.Add($chkAll)

    $result = $cForm.ShowDialog()
    return @{ Action = $result; ApplyAll = $chkAll.Checked }
}

# ===== 自定义完成弹窗函数 =====
function Show-CustomDoneBox($success, $fail, $time) {
    $doneForm = New-Object System.Windows.Forms.Form
    $doneForm.Text = "处理完毕"
    $doneForm.Size = "320, 240"
    $doneForm.StartPosition = "CenterParent"
    $doneForm.FormBorderStyle = "FixedDialog"
    $doneForm.MaximizeBox = $false
    $doneForm.MinimizeBox = $false
    $doneForm.BackColor = [System.Drawing.Color]::White

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "任务完成"
    $lblTitle.Font = $fontLargeBold
    $lblTitle.ForeColor = $theme.SuccessColor
    $lblTitle.Size = "300, 40"
    $lblTitle.Location = "0, 25"
    $lblTitle.TextAlign = "MiddleCenter"
    $doneForm.Controls.Add($lblTitle)

    $lblDetail = New-Object System.Windows.Forms.Label
    $lblDetail.Text = "成功: $success   |   失败: $fail"
    $lblDetail.Font = $fontMain
    $lblDetail.Size = "300, 30"
    $lblDetail.Location = "0, 75"
    $lblDetail.TextAlign = "MiddleCenter"
    $doneForm.Controls.Add($lblDetail)

    $lblTime = New-Object System.Windows.Forms.Label
    $lblTime.Text = "总耗时: $time"
    $lblTime.Font = $fontSmall
    $lblTime.ForeColor = [System.Drawing.Color]::Gray
    $lblTime.Size = "300, 30"
    $lblTime.Location = "0, 105"
    $lblTime.TextAlign = "MiddleCenter"
    $doneForm.Controls.Add($lblTime)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "确 定"
    $btnOk.Size = "100, 35"
    $btnOk.Location = "105, 145"
    $btnOk.FlatStyle = "Flat"
    $btnOk.BackColor = $theme.PrimaryColor
    $btnOk.ForeColor = [System.Drawing.Color]::White
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $doneForm.Controls.Add($btnOk)

    $doneForm.ShowDialog()
}

# ===== 窗体设置 =====
$form = New-Object System.Windows.Forms.Form
$form.Text = "🚀 极速音频增强工具 Pro v2.1"
$form.Size = "650, 780" # 稍微调高一点容纳比特率设置
$form.BackColor = $theme.BgColor
$form.StartPosition = "CenterScreen"
$form.Font = $fontMain
$form.AllowDrop = $true
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($form, $true)

# 路径选择
$groupPath = New-Object System.Windows.Forms.Panel
$groupPath.Size = "610, 140"
$groupPath.Location = "15, 15"
$groupPath.BackColor = $theme.CardColor
$form.Controls.Add($groupPath)

$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "音频文件夹路径"
$lblPath.Font = $fontBold
$lblPath.Location = "15, 15"
$lblPath.AutoSize = $true
$groupPath.Controls.Add($lblPath)

$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Text = $lastPath
$txtPath.Location = "15, 45"
$txtPath.Size = "450, 30"
$groupPath.Controls.Add($txtPath)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "浏览..."
$btnBrowse.Location = "480, 43"
$btnBrowse.Size = "110, 32"
$btnBrowse.FlatStyle = "Flat"
$btnBrowse.BackColor = $theme.PrimaryColor
$btnBrowse.ForeColor = [System.Drawing.Color]::White
$btnBrowse.FlatAppearance.BorderSize = 0
$groupPath.Controls.Add($btnBrowse)

$dropLabel = New-Object System.Windows.Forms.Label
$dropLabel.Text = " 拖拽文件夹至此处快速导入"
$dropLabel.Location = "15, 85"
$dropLabel.Size = "575, 40"
$dropLabel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$dropLabel.TextAlign = "MiddleCenter"
$dropLabel.ForeColor = [System.Drawing.Color]::Gray
$groupPath.Controls.Add($dropLabel)

# 参数设置
$groupSet = New-Object System.Windows.Forms.Panel
$groupSet.Size = "610, 240" # 增加高度
$groupSet.Location = "15, 170"
$groupSet.BackColor = $theme.CardColor
$form.Controls.Add($groupSet)

$lblVolTitle = New-Object System.Windows.Forms.Label
$lblVolTitle.Text = "🔊 音量调节 (倍数\分贝)"
$lblVolTitle.Font = $fontBold
$lblVolTitle.Location = "15, 10"
$lblVolTitle.AutoSize = $true
$groupSet.Controls.Add($lblVolTitle)

$sliderVol = New-Object System.Windows.Forms.TrackBar
$sliderVol.Minimum = 1
$sliderVol.Maximum = 100
$sliderVol.Value = 25
$sliderVol.Location = "15, 35"
$sliderVol.Width = 350
$groupSet.Controls.Add($sliderVol)

$lblVolRatio = New-Object System.Windows.Forms.Label
$lblVolRatio.Location = "380, 40"
$lblVolRatio.Text = "2.5x ="
$lblVolRatio.AutoSize = $true
$groupSet.Controls.Add($lblVolRatio)

$txtVolDb = New-Object System.Windows.Forms.TextBox
$txtVolDb.Location = "435, 37"
$txtVolDb.Size = "60, 25"
$txtVolDb.Text = "8.0"
$txtVolDb.ReadOnly = $true
$txtVolDb.TabStop = $false
$txtVolDb.BackColor = [System.Drawing.Color]::WhiteSmoke
$txtVolDb.TextAlign = "Center"
$groupSet.Controls.Add($txtVolDb)

$lblDbUnit = New-Object System.Windows.Forms.Label
$lblDbUnit.Location = "500, 40"
$lblDbUnit.Text = "dB"
$groupSet.Controls.Add($lblDbUnit)

$lblThreadTitle = New-Object System.Windows.Forms.Label
$lblThreadTitle.Text = "⚡ 并发处理数"
$lblThreadTitle.Font = $fontBold
$lblThreadTitle.Location = "15, 80"
$lblThreadTitle.AutoSize = $true
$groupSet.Controls.Add($lblThreadTitle)

$sliderThread = New-Object System.Windows.Forms.TrackBar
$sliderThread.Minimum = 1
$sliderThread.Maximum = [Environment]::ProcessorCount
$sliderThread.Value = [Math]::Max(1, [int]($sliderThread.Maximum / 2))
$sliderThread.Location = "15, 100"
$sliderThread.Width = 350
$groupSet.Controls.Add($sliderThread)

$lblThread = New-Object System.Windows.Forms.Label
$lblThread.Location = "380, 105"
$lblThread.Text = "$($sliderThread.Value) 线程（不高于CPU核心）"
$lblThread.AutoSize = $true
$groupSet.Controls.Add($lblThread)

# 比特率设置
$lblBitTitle = New-Object System.Windows.Forms.Label
$lblBitTitle.Text = "💎 比特率设置"
$lblBitTitle.Font = $fontBold
$lblBitTitle.Location = "15, 145"
$lblBitTitle.AutoSize = $true
$groupSet.Controls.Add($lblBitTitle)

$rbBitOrig = New-Object System.Windows.Forms.RadioButton
$rbBitOrig.Text = "使用原始比特率"
$rbBitOrig.Location = "15, 170"
$rbBitOrig.Size = "130, 25"
$rbBitOrig.Checked = $false
$groupSet.Controls.Add($rbBitOrig)

$rbBitFixed = New-Object System.Windows.Forms.RadioButton
$rbBitFixed.Text = "固定比特率:"
$rbBitFixed.Location = "160, 170"
$rbBitFixed.Size = "100, 25"
$rbBitFixed.Checked = $true
$groupSet.Controls.Add($rbBitFixed)

$txtBitValue = New-Object System.Windows.Forms.TextBox
$txtBitValue.Text = "64"
$txtBitValue.Location = "260, 170"
$txtBitValue.Size = "50, 25"
$txtBitValue.TextAlign = "Center"
$groupSet.Controls.Add($txtBitValue)

$lblBitUnit = New-Object System.Windows.Forms.Label
$lblBitUnit.Text = "kbps"
$lblBitUnit.Location = "315, 173"
$lblBitUnit.AutoSize = $true
$groupSet.Controls.Add($lblBitUnit)

$chkNorm = New-Object System.Windows.Forms.CheckBox
$chkNorm.Text = "启用动态平衡 (智能修剪高低频，有效防止爆音破音)"
$chkNorm.Location = "20, 205"
$chkNorm.Size = "500, 30"
$chkNorm.Font = $fontSmall
$chkNorm.Checked = $false
$groupSet.Controls.Add($chkNorm)

# 操作按钮
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "🚀 开始处理"
$btnStart.Location = "15, 425"
$btnStart.Size = "145, 45"
$btnStart.FlatStyle = "Flat"
$btnStart.BackColor = $theme.SuccessColor
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.Font = $fontBold
$btnStart.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnStart)

$btnPause = New-Object System.Windows.Forms.Button
$btnPause.Text = "⏸ 暂停"
$btnPause.Location = "165, 425"
$btnPause.Size = "70, 45"
$btnPause.FlatStyle = "Flat"
$btnPause.BackColor = $theme.WarningColor
$btnPause.ForeColor = [System.Drawing.Color]::White
$btnPause.Font = $fontBold
$btnPause.Enabled = $false
$btnPause.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnPause)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "⏹ 停止"
$btnStop.Location = "240, 425"
$btnStop.Size = "70, 45"
$btnStop.FlatStyle = "Flat"
$btnStop.BackColor = $theme.DangerColor
$btnStop.ForeColor = [System.Drawing.Color]::White
$btnStop.Font = $fontBold
$btnStop.Enabled = $false
$btnStop.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnStop)

$btnOpenOut = New-Object System.Windows.Forms.Button
$btnOpenOut.Text = "📂 打开输出目录"
$btnOpenOut.Location = "330, 425"
$btnOpenOut.Size = "295, 45"
$btnOpenOut.FlatStyle = "Flat"
$btnOpenOut.BackColor = $theme.PrimaryColor
$btnOpenOut.ForeColor = [System.Drawing.Color]::White
$btnOpenOut.Font = $fontBold
$btnOpenOut.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnOpenOut)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = "15, 485"
$progress.Size = "610, 15"
$form.Controls.Add($progress)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "准备就绪"
$lblStatus.Location = "15, 505"
$lblStatus.Size = "610, 25"
$lblStatus.TextAlign = "MiddleRight"
$lblStatus.Font = $fontSmall
$form.Controls.Add($lblStatus)

$log = New-Object System.Windows.Forms.TextBox
$log.Location = "15, 535"
$log.Size = "610, 185"
$log.Multiline = $true
$log.ScrollBars = "Vertical"
$log.BackColor = $theme.LogBg
$log.ForeColor = $theme.LogFg
$log.Font = New-Object System.Drawing.Font("Consolas", 9)
$log.BorderStyle = "None"
$log.ReadOnly = $true
$form.Controls.Add($log)

# 交互逻辑
$sliderVol.Add_Scroll({
    $ratio = $sliderVol.Value / 10
    $lblVolRatio.Text = "$ratio" + "x ="
    $db = [Math]::Round(20 * [Math]::Log10($ratio), 1)
    $txtVolDb.Text = $db.ToString("F1")
})

$sliderThread.Add_Scroll({ $lblThread.Text = "$($sliderThread.Value) 线程" })

$btnBrowse.Add_Click({
    $fd = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fd.ShowDialog() -eq "OK") { $txtPath.Text = $fd.SelectedPath }
})

$form.Add_DragEnter({
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) { 
        $_.Effect = "Copy" 
        $dropLabel.BackColor = [System.Drawing.Color]::LightBlue
    }
})
$form.Add_DragLeave({ $dropLabel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240) })
$form.Add_DragDrop({
    $files = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if (Test-Path $files[0] -PathType Container) { $txtPath.Text = $files[0] }
    $dropLabel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
})

$btnOpenOut.Add_Click({
    if ($global:outputDir -and (Test-Path $global:outputDir)) { Start-Process explorer.exe $global:outputDir }
    else { [System.Windows.Forms.MessageBox]::Show("尚未开始处理或目录不存在。") }
})

$btnPause.Add_Click({
    if ($global:isPaused) {
        $global:isPaused = $false
        $btnPause.Text = "⏸ 暂停"
        $log.AppendText("▶ 任务继续...`r`n")
    } else {
        $global:isPaused = $true
        $btnPause.Text = "▶ 继续"
        $log.AppendText("⏸ 任务已暂停...`r`n")
    }
})

$btnStop.Add_Click({
    $global:isStopped = $true
    $log.AppendText("⏹ 正在停止任务并清理...`r`n")
})

# 处理核心
$btnStart.Add_Click({
    $inputDir = $txtPath.Text.Trim()
    if (!(Test-Path $inputDir)) { [System.Windows.Forms.MessageBox]::Show("请输入有效的文件夹路径。"); return }

    Set-Content $configFile $inputDir
    $ffmpeg = Join-Path $PSScriptRoot "ffmpeg.exe"
    $ffprobe = Join-Path $PSScriptRoot "ffprobe.exe"
    if (!(Test-Path $ffmpeg)) { [System.Windows.Forms.MessageBox]::Show("目录下缺少 ffmpeg.exe"); return }

    $files = Get-ChildItem -Path $inputDir -File | Where-Object { $_.Extension -match "\.(mp3|wav|m4a|flac|aac)$" }
    if ($files.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("未发现音频文件。"); return }

    $global:outputDir = Join-Path $inputDir "Enhanced_Output"
    if (!(Test-Path $global:outputDir)) { New-Item -ItemType Directory -Force -Path $global:outputDir | Out-Null }

    $targetDb = $txtVolDb.Text
    $maxThreads = $sliderThread.Value
    $useNorm = $chkNorm.Checked
    
    # 获取比特率设置
    $isFixedBitrate = $rbBitFixed.Checked
    $fixedBitrateVal = $txtBitValue.Text.Trim()
    
    $progress.Maximum = $files.Count
    $progress.Value = 0
    $log.Clear()
    
    $global:isPaused = $false
    $global:isStopped = $false
    $btnStart.Enabled = $false
    $btnPause.Enabled = $true
    $btnStop.Enabled = $true
    $btnStart.Text = "正在处理..."

    # --- 冲突检测预处理 ---
    $fileTaskPairs = New-Object System.Collections.Generic.List[object]
    $globalAction = "None" 
    
    foreach ($f in $files) {
        $expectedName = $f.BaseName + ".mp3"
        $fullOutPath = Join-Path $global:outputDir $expectedName
        
        if (Test-Path $fullOutPath) {
            if ($globalAction -eq "None") {
                $res = Show-ConflictDialog -fileName $expectedName
                if ($res.Action -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $currentAction = "Overwrite"
                } else {
                    $currentAction = "Rename"
                }
                if ($res.ApplyAll) { $globalAction = $currentAction }
            } else {
                $currentAction = $globalAction
            }

            if ($currentAction -eq "Rename") {
                $expectedName = "V_" + $f.BaseName + ".mp3"
                $fullOutPath = Join-Path $global:outputDir $expectedName
            }
        }
        $fileTaskPairs.Add(@{ File = $f; TargetName = $expectedName })
    }

    $rsPool = [runspacefactory]::CreateRunspacePool(1, $maxThreads)
    $rsPool.Open()
    $jobs = New-Object System.Collections.Generic.List[object]

    $scriptBlock = {
        param($f, $outDir, $targetName, $ffmpeg, $ffprobe, $db, $useNorm, $isFixed, $fixedVal)
        try {
            $outPath = Join-Path $outDir $targetName
            
            # 确定比特率
            $finalBitrate = ""
            if ($isFixed) {
                $finalBitrate = $fixedVal + "k"
            } else {
                # 尝试获取原始比特率
                if (Test-Path $ffprobe) {
                    $origBitrate = & $ffprobe -v error -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$($f.FullName)"
                    if ($origBitrate -match '^\d+$') {
                        $finalBitrate = [string]([int]$origBitrate / 1000) + "k"
                    }
                }
                if ([string]::IsNullOrEmpty($finalBitrate)) { $finalBitrate = "128k" } # 回退方案
            }

            $filter = if ($useNorm) { 
                "volume=${db}dB,dynaudnorm=p=0.9:m=100,alimiter=limit=0.95" 
            } else { 
                "volume=${db}dB,alimiter=limit=0.95" 
            }
            
            & $ffmpeg -y -loglevel error -i "$($f.FullName)" -af "$filter" -c:a libmp3lame -b:a $finalBitrate -ar 44100 "$outPath" 2>$null
            if ($LASTEXITCODE -eq 0) { return "OK|"+$f.Name } else { return "FAIL|"+$f.Name }
        } catch { return "FAIL|"+$f.Name }
    }

    $failCount = 0
    $startTime = Get-Date
    $pairIndex = 0

    while ($pairIndex -lt $fileTaskPairs.Count -or $jobs.Count -gt 0) {
        [System.Windows.Forms.Application]::DoEvents()

        if ($global:isStopped) {
            $log.AppendText("❌ 任务已被用户强制停止。`r`n")
            foreach ($j in $jobs) { $j.ps.Stop() }
            $jobs.Clear()
            break
        }

        if ($global:isPaused) {
            Start-Sleep -Milliseconds 200
            continue
        }

        while ($jobs.Count -lt $maxThreads -and $pairIndex -lt $fileTaskPairs.Count) {
            $pair = $fileTaskPairs[$pairIndex]
            $ps = [powershell]::Create().AddScript($scriptBlock).AddArgument($pair.File).AddArgument($global:outputDir).AddArgument($pair.TargetName).AddArgument($ffmpeg).AddArgument($ffprobe).AddArgument($targetDb).AddArgument($useNorm).AddArgument($isFixedBitrate).AddArgument($fixedBitrateVal)
            $ps.RunspacePool = $rsPool
            $jobs.Add(@{ ps = $ps; handle = $ps.BeginInvoke() })
            $pairIndex++
        }

        $finished = $jobs | Where-Object { $_.handle.IsCompleted }
        foreach ($job in $finished) {
            $result = $job.ps.EndInvoke($job.handle)
            $job.ps.Dispose()
            $status, $fileName = $result.Split('|')
            if ($status -eq "OK") { $log.AppendText("✔ [成功] $fileName`r`n") } 
            else { $log.AppendText("❌ [失败] $fileName`r`n"); $failCount++ }
            
            $log.SelectionStart = $log.Text.Length
            $log.ScrollToCaret()
            $progress.Value++
            $jobs.Remove($job)
        }

        $elapsed = (Get-Date) - $startTime
        $lblStatus.Text = "进度: $($progress.Value)/$($files.Count) | 失败: $failCount | 用时: $($elapsed.ToString("hh\:mm\:ss"))"
        Start-Sleep -Milliseconds 20
    }

    $rsPool.Close()
    $rsPool.Dispose()
    
    $btnStart.Enabled = $true
    $btnPause.Enabled = $false
    $btnStop.Enabled = $false
    $btnPause.Text = "⏸ 暂停"
    $btnStart.Text = "🚀 开始处理"
    
    if (-not $global:isStopped) {
        $totalTimeStr = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
        Show-CustomDoneBox -success ($progress.Value - $failCount) -fail $failCount -time $totalTimeStr
    }
})

$form.ShowDialog()