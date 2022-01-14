(local spine (require :spine-love.spine))

(local skeleton-renderer (spine.SkeletonRenderer.new true))

(local Spine {})
(set Spine.__index Spine)

(fn Spine.update [self dt]
  (self.state:update dt)
  (self.state:apply self.skeleton)
  (self.skeleton:updateWorldTransform))

(fn Spine.draw [self]
  (skeleton-renderer:draw self.skeleton))

(fn spineasset [name initial-anim]
 (let [atlas (spine.TextureAtlas.new
              (spine.utils.readFile (.. "assets/" name ".atlas"))
              #(love.graphics.newImage (.. "assets/" $1)))
       json (spine.SkeletonJson.new (spine.AtlasAttachmentLoader.new atlas))
       skeletonData (json:readSkeletonDataFile (.. "assets/" name ".json"))]
  (fn []
    (let [skeleton (spine.Skeleton.new skeletonData)
          self (setmetatable {: atlas : json : skeletonData : skeleton} Spine)]
     (set self.stateData (spine.AnimationStateData.new self.skeletonData))
     (set self.state (spine.AnimationState.new self.stateData))
     (self.state:setAnimationByName 0 initial-anim true)
     (self.skeleton:setToSetupPose)
     self))))

{: spineasset}
