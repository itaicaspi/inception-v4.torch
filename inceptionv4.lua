require 'nn'

local function Tower(layers)
  local tower = nn.Sequential()
  for i=1,#layers do
    tower:add(layers[i])
  end
  return tower
end

local function FilterConcat(towers)
  local concat = nn.DepthConcat(2)
  for i=1,#towers do
    concat:add(towers[i])
  end
  return concat
end

local function Stem()
  local stem = nn.Sequential()
  stem:add(nn.SpatialConvolution(3, 32, 3, 3, 2, 2)) -- 32x149x149
  stem:add(nn.SpatialConvolution(32, 32, 3, 3, 1, 1)) -- 32x147x147
  stem:add(nn.SpatialConvolution(32, 64, 3, 3, 1, 1, 1, 1)) -- 64x147x147
  stem:add(FilterConcat(
    {
      nn.SpatialMaxPooling(3, 3, 2, 2), -- 96x73x73
      nn.SpatialConvolution(64, 96, 3, 3, 2, 2) -- 64x73x73
    }
  )) -- 160x73x73
  stem:add(FilterConcat(
    {
      Tower(
        {
          nn.SpatialConvolution(160, 64, 1, 1, 1, 1),
          nn.SpatialConvolution(64, 96, 3, 3, 1, 1)
        }
      ),
      Tower(
        {
          nn.SpatialConvolution(160, 64, 1, 1, 1, 1),
          nn.SpatialConvolution(64, 64, 7, 1, 1, 1),
          nn.SpatialConvolution(64, 64, 1, 7, 1, 1),
          nn.SpatialConvolution(64, 96, 3, 3, 1, 1)
        }
      )
    }
  ))
  stem:add(FilterConcat(
    {
      nn.SpatialConvolution(192, 192, 3, 3, 1, 1),
      nn.SpatialMaxPooling(3, 3, 2, 2)
    }
  ))
  return stem
end

local function Inception_A()
  local inception = FilterConcat(
    {
      Tower(
        {
          nn.SpatialAveragePooling(3, 3),
          nn.SpatialConvolution(384, 96, 1, 1, 1, 1)
        }
      ),
      nn.SpatialConvolution(384, 96, 1, 1, 1, 1),
      Tower(
        {
          nn.SpatialConvolution(384, 64, 1, 1, 1, 1),
          nn.SpatialConvolution(64, 96, 3, 3, 1, 1)
        }
      ),
      Tower(
        {
          nn.SpatialConvolution(384, 64, 1, 1, 1, 1),
          nn.SpatialConvolution(64, 96, 3, 3, 1, 1),
          nn.SpatialConvolution(96, 96, 3, 3, 1, 1),
        }
      )
    }
  )
  -- 384 ifms / ofms
  return inception
end

local function Inception_B()
  local inception = FilterConcat(
    {
      Tower(
        {
          nn.SpatialAveragePooling(3, 3),
          nn.SpatialConvolution(1024, 128, 1, 1, 1, 1):celi()
        }
      ),
      nn.SpatialConvolution(1024, 384, 1, 1, 1, 1),
      Tower(
        {
          nn.SpatialConvolution(1024, 192, 1, 1, 1, 1),
          nn.SpatialConvolution(192, 224, 1, 7, 1, 1),
          nn.SpatialConvolution(224, 256, 1, 7, 1, 1)
        }
      ),
      Tower(
        {
          nn.SpatialConvolution(1024, 192, 1, 1, 1, 1),
          nn.SpatialConvolution(192, 192, 1, 7, 1, 1),
          nn.SpatialConvolution(192, 224, 7, 1, 1, 1),
          nn.SpatialConvolution(224, 224, 1, 7, 1, 1),
          nn.SpatialConvolution(224, 256, 7, 1, 1, 1),
        }
      )
    }
  )
  -- 1024 ifms / ofms
  return inception
end


local function Inception_C()
  local inception = FilterConcat(
    {
      Tower(
        {
          nn.SpatialAveragePooling(3, 3),
          nn.SpatialConvolution(1536, 256, 1, 1, 1, 1)
        }
      ),
      nn.SpatialConvolution(1536, 256, 1, 1, 1, 1),
      Tower(
        {
          nn.SpatialConvolution(1536, 384, 1, 1, 1, 1),
          FiltreConcat(
            {
              nn.SpatialConvolution(384, 256, 1, 3, 1, 1),
              nn.SpatialConvolution(384, 256, 3, 1, 1, 1)
            }
          )
        }
      ),
      Tower(
        {
          nn.SpatialConvolution(1536, 384, 1, 1, 1, 1),
          nn.SpatialConvolution(384, 448, 1, 3, 1, 1),
          nn.SpatialConvolution(448, 512, 3, 1, 1, 1),
          FilterConcat(
            {
              nn.SpatialConvolution(512, 256, 3, 1, 1, 1),
              nn.SpatialConvolution(512, 256, 1, 3, 1, 1)
            }
          )
        }
      )
    }
  )
  -- 1536 ifms / ofms
  return inception
end

local function Reductoin_A()
  local inception = FilterConcat(
    {
      nn.SpatialMaxPooling(3, 3, 2, 2),
      nn.SpatialConvolution(384, 384, 3, 3, 2, 2),
      Tower(
        {
          nn.SpatialConvolution(384, 192, 1, 1, 1, 1),
          nn.SpatialConvolution(192, 224, 3, 3, 1, 1),
          nn.SpatialConvolution(224, 256, 3, 3, 2, 2),
        }
      )
    }
  )
  -- 384 ifms, 1024 ofms
  return inception
end

local function Reductoin_B()
  local inception = FilterConcat(
    {
      nn.SpatialMaxPooling(3, 3, 2, 2),
      Tower(
        {
          nn.SpatialConvolution(1024, 192, 1, 1, 1, 1),
          nn.SpatialConvolution(192, 192, 3, 3, 2, 2)
        }
      ),
      Tower(
        {
          nn.SpatialConvolution(1024, 256, 1, 1, 1, 1),
          nn.SpatialConvolution(256, 256, 1, 7, 1, 1),
          nn.SpatialConvolution(256, 320, 7, 1, 1, 1),
          nn.SpatialConvolution(320, 320, 3, 3, 2, 2)
        }
      )
    }
  )
  -- 1024 ifms, 1536 ofms
  return inception
end

-- Overall schema of the Inception-v4 network
local net = nn.Sequential()
print("-- Stem")
net:add(Stem())           -- 299x299x3 ==> 35x35x384
print("-- Inception-A x 4")
for i=1,4 do
  net:add(Inception_A())  -- 35x35x384 ==> 35x35x384
end
print("-- Reduction-A")
net:add(Reduction_A())    -- 35x35x384 ==> 17x17x1024
print("-- Inception-B x 7")
for i=1,7 do
  net:add(Inception_B())  -- 17x17x1024 ==> 17x17x1024
end
print("-- Reduction-B")
net:add(Reduction_B())    -- 17x17x1024 ==> 8x8x1536
print("-- Inception-C x 3")
for i=1,3 do
  net:add(Inception_C())  -- 8x8x1536 ==> 8x8x1536
end
print("-- Average Pooling")
net:add(nn.SpatialAveragePooling(8, 8)) -- 8x8x1536 ==> 1x1x1536
print("-- Dropout")
net:add(nn.Dropout(0.2))
print("-- Fully Connected")
net:add(nn.Linear(1536, 1000))  -- 1536 ==> 1000
print("-- SoftMax")
net:add(nn.SoftMax())

net:evaluate()
torch.save(args.o, net, "binary")
