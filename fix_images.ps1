Add-Type -AssemblyName System.Drawing

$directories = @(
    "c:\Users\qarel\SDK\daily_development\lib\assets\Head",
    "c:\Users\qarel\SDK\daily_development\lib\assets\Body1Set"
)

foreach ($dir in $directories) {
    $files = Get-ChildItem -Path $dir -Filter "*.png"
    foreach ($file in $files) {
        $imgPath = $file.FullName
        Write-Host "Converting $imgPath..."
        
        try {
            # Read the image bytes completely into memory so the file is not locked
            $imageBytes = [System.IO.File]::ReadAllBytes($imgPath)
            $ms = New-Object System.IO.MemoryStream(,$imageBytes)
            $image = [System.Drawing.Image]::FromStream($ms)
            
            # Create a new bitmap with standard ARGB format (32-bit)
            $bitmap = New-Object System.Drawing.Bitmap($image.Width, $image.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            
            # Draw the original image onto the new bitmap
            $graphics.DrawImage($image, 0, 0, $image.Width, $image.Height)
            
            # Dispose original so we can overwrite
            $graphics.Dispose()
            $image.Dispose()
            $ms.Dispose()
            
            # Overwrite the original file with standard PNG encoding
            $bitmap.Save($imgPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $bitmap.Dispose()
            
            Write-Host "Success: $imgPath"
        } catch {
            Write-Host "Failed to convert: $imgPath - $_"
        }
    }
}
Write-Host "All done!"
