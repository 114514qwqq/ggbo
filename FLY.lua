-- 手机端飞行脚本
-- 点击屏幕右侧按钮激活/取消飞行
-- 左侧滑动控制方向

local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

-- 配置
local DEFAULT_SPEED = 30
local MAX_SPEED = 100
local MIN_SPEED = 10
local TOUCH_THROTTLE = 0.1 -- 触摸控制灵敏度

-- 飞行状态
local flying = false
local currentSpeed = DEFAULT_SPEED
local bodyVelocity
local bodyGyro
local touchStartPos
local touchActive = false

-- 创建手机UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileFlightGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

-- 飞行开关按钮 (右侧)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleFlight"
ToggleButton.Size = UDim2.new(0, 120, 0, 50)
ToggleButton.Position = UDim2.new(1, -130, 1, -60)
ToggleButton.AnchorPoint = Vector2.new(0, 1)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
ToggleButton.TextColor3 = Color3.white
ToggleButton.Text = "开启飞行"
ToggleButton.Font = Enum.Font.SourceHanSansCN
ToggleButton.TextSize = 18
ToggleButton.BorderSizePixel = 0
ToggleButton.ZIndex = 10
ToggleButton.Parent = ScreenGui

-- 速度显示标签
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Name = "SpeedDisplay"
SpeedLabel.Size = UDim2.new(0, 120, 0, 30)
SpeedLabel.Position = UDim2.new(1, -130, 1, -120)
SpeedLabel.AnchorPoint = Vector2.new(0, 1)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "速度: "..currentSpeed
SpeedLabel.TextColor3 = Color3.white
SpeedLabel.Font = Enum.Font.SourceHanSansCN
SpeedLabel.TextSize = 16
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.ZIndex = 10
SpeedLabel.Parent = ScreenGui

-- 方向控制区域 (左侧半屏)
local TouchControlFrame = Instance.new("Frame")
TouchControlFrame.Name = "DirectionPad"
TouchControlFrame.Size = UDim2.new(0.5, 0, 1, 0)
TouchControlFrame.BackgroundTransparency = 1
TouchControlFrame.Visible = false
TouchControlFrame.Parent = ScreenGui

-- 方向指示器
local DirectionIndicator = Instance.new("Frame")
DirectionIndicator.Name = "Joystick"
DirectionIndicator.Size = UDim2.new(0, 60, 0, 60)
DirectionIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
DirectionIndicator.Position = UDim2.new(0.25, 0, 0.5, 0)
DirectionIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DirectionIndicator.BackgroundTransparency = 0.7
DirectionIndicator.BorderSizePixel = 0
DirectionIndicator.ZIndex = 5
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = DirectionIndicator
DirectionIndicator.Parent = TouchControlFrame

-- 飞行功能
local function startFlying()
    if flying then return end
    
    local character = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.PlatformStand = true
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.CFrame = (character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")).CFrame
    bodyGyro.Parent = bodyVelocity.Parent
    
    flying = true
    ToggleButton.Text = "关闭飞行"
    TouchControlFrame.Visible = true
    
    -- 手机震动反馈
    if GuiService:IsTenFootInterface() == false then
        game:GetService("HapticService"):SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Large, 0.5)
        task.delay(0.2, function()
            game:GetService("HapticService"):SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Large, 0)
        end)
    end
end

local function stopFlying()
    if not flying then return end
    
    local character = Player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            for _, v in ipairs(rootPart:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
                    v:Destroy()
                end
            end
        end
    end
    
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    
    flying = false
    ToggleButton.Text = "开启飞行"
    TouchControlFrame.Visible = false
end

local function toggleFlight()
    if flying then
        stopFlying()
    else
        startFlying()
    end
end

-- 触摸控制
local function updateDirection(input)
    if not flying or not input then return end
    
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local touchPos = input.Position
    local center = Vector2.new(viewportSize.X * 0.25, viewportSize.Y * 0.5)
    local delta = (touchPos - center)
    
    -- 限制摇杆移动范围
    local maxDist = 100
    if delta.Magnitude > maxDist then
        delta = delta.Unit * maxDist
    end
    
    -- 更新摇杆位置
    DirectionIndicator.Position = UDim2.new(0, center.X + delta.X, 0, center.Y + delta.Y)
    
    -- 计算方向向量
    local forward = workspace.CurrentCamera.CFrame.LookVector
    local right = workspace.CurrentCamera.CFrame.RightVector
    
    local direction = Vector3.new(0, 0, 0)
    direction = direction + (forward * (delta.Y / maxDist * -1)) -- 前后
    direction = direction + (right * (delta.X / maxDist)) -- 左右
    
    if direction.Magnitude > 0 then
        direction = direction.Unit * currentSpeed
        bodyVelocity.Velocity = direction
    else
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end

-- 触摸事件处理
UserInputService.TouchStarted:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- 检查是否点击了左侧控制区域
    if input.Position.X < workspace.CurrentCamera.ViewportSize.X / 2 then
        touchActive = true
        touchStartPos = input.Position
        if flying then
            updateDirection(input)
        end
    end
end)

UserInputService.TouchMoved:Connect(function(input, gameProcessed)
    if not touchActive then return end
    if flying then
        updateDirection(input)
    end
end)

UserInputService.TouchEnded:Connect(function(input, gameProcessed)
    touchActive = false
    if flying then
        -- 重置摇杆位置
        local tween = TweenService:Create(
            DirectionIndicator,
            TweenInfo.new(0.2),
            {Position = UDim2.new(0.25, 0, 0.5, 0)}
        )
        tween:Play()
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- 按钮事件
ToggleButton.MouseButton1Click:Connect(toggleFlight)

-- 速度控制 (长按加速)
local speedChangeCooldown = false
ToggleButton.TouchLongPress:Connect(function()
    if speedChangeCooldown then return end
    speedChangeCooldown = true
    
    local newSpeed = currentSpeed + 20
    if newSpeed > MAX_SPEED then
        newSpeed = MIN_SPEED
    end
    currentSpeed = newSpeed
    SpeedLabel.Text = "速度: "..currentSpeed
    
    -- 震动反馈
    if GuiService:IsTenFootInterface() == false then
        game:GetService("HapticService"):SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Small, 0.3)
        task.delay(0.1, function()
            game:GetService("HapticService"):SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Small, 0)
        end)
    end
    
    task.delay(0.5, function()
        speedChangeCooldown = false
    end)
end)

-- 角色变化时重置飞行
Player.CharacterAdded:Connect(function()
    stopFlying()
end)

-- 初始提示
local function showNotification(message)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "手机飞行控制",
        Text = message,
        Duration = 5,
        Icon = "rbxassetid://6726579484" -- 使用飞行图标
    })
end

showNotification("手机飞行控制已加载\n点击右侧按钮开启飞行\n左侧半屏滑动控制方向\n长按按钮切换速度")
