local esp = {}
local act = {}
local rs = game:GetService("RunService")
local cam = workspace.CurrentCamera

local function mk(p)
    local t = Drawing.new("Text")
    t.Center = true
    t.Outline = true
    t.Visible = false
    t.Size = p.sz or 14
    t.Color = p.col or Color3.new(1,1,1)
    t.OutlineColor = p.ocol or Color3.new(0,0,0)
    return t
end

local function pos(obj)
    local cf = obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj:IsA("BasePart") and obj
    if not cf then return nil end
    local p, v = cam:WorldToViewportPoint(cf.Position + Vector3.new(0, 3, 0))
    return v and Vector2.new(p.X, p.Y) or nil
end

local function hl(obj, col)
    local h = Instance.new("Highlight")
    h.FillColor = col or Color3.new(1,0,0)
    h.OutlineColor = col or Color3.new(1,1,1)
    h.FillTransparency = 0.7
    h.Adornee = obj
    h.Parent = game.CoreGui
    return h
end

function esp:Add(cfg)
    local tgt = cfg.targets or {}
    local nms = cfg.names or {}
    local col = cfg.color or Color3.new(1,1,1)
    local ocol = cfg.outlineColor or Color3.new(0,0,0)
    local sz = cfg.size or 14
    local hle = cfg.highlight or false
    local hcol = cfg.highlightColor or Color3.new(1,0,0)
    local numf = cfg.numberFunc
    local id = tostring(tick())
    
    act[id] = {objs = {}, con = nil, root = cfg.parent or workspace}
    
    local function add(obj, nm)
        if act[id].objs[obj] then return end
        local d = {txt = mk({sz=sz, col=col, ocol=ocol}), hl = hle and hl(obj, hcol) or nil, nm = nm, nf = numf}
        act[id].objs[obj] = d
    end
    
    local function scan()
        for i, n in ipairs(tgt) do
            for _, v in ipairs(act[id].root:GetDescendants()) do
                if v.Name == n then
                    add(v, nms[i] or n)
                end
            end
        end
    end
    
    scan()
    
    act[id].root.DescendantAdded:Connect(function(v)
        task.defer(function()
            for i, n in ipairs(tgt) do
                if v.Name == n then add(v, nms[i] or n) end
            end
        end)
    end)
    
    act[id].con = rs.RenderStepped:Connect(function()
        for obj, d in pairs(act[id].objs) do
            if not obj or not obj.Parent then
                d.txt:Remove()
                if d.hl then d.hl:Destroy() end
                act[id].objs[obj] = nil
            else
                local p = pos(obj)
                if p then
                    local tx = d.nm
                    if d.nf then
                        local num = d.nf(obj)
                        if num then tx = tx .. " [" .. tostring(num) .. "]" end
                    end
                    d.txt.Text = tx
                    d.txt.Position = p
                    d.txt.Visible = true
                else
                    d.txt.Visible = false
                end
            end
        end
    end)
    
    return id
end

function esp:Remove(id)
    if not act[id] then return end
    for _, d in pairs(act[id].objs) do
        d.txt:Remove()
        if d.hl then d.hl:Destroy() end
    end
    if act[id].con then act[id].con:Disconnect() end
    act[id] = nil
end

function esp:Clear()
    for id in pairs(act) do self:Remove(id) end
end

return esp
