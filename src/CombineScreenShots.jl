import FileIO: load, save
import ImageTransformations: imresize
import Dates: today
# import ImageView: imshow # imshow(vcat_img)

function CombineScreenShots(;
    imgs_dir = joinpath(homedir(), "Desktop"),
    logo_dir = joinpath(homedir(), "Documents/Meta/Technique/Website/logo/Likan.Zhan.Weibo.jpeg"),
    outs_dir = joinpath(imgs_dir, string("Combined-", today(), ".jpg"))
    )

    img_list = filter(Base.Fix1(occursin, "Screen Shot"), readdir(imgs_dir, join = true) )
    sort!(img_list)

    function image_resize(img_name)
        old_image = load(img_name);
        resize_ratio = size(old_image, 2) / 2000
        new_size = round.(Int, size(old_image) ./ resize_ratio)
        new_image = imresize(old_image, new_size)
        return new_image
    end

    vcat_img = mapreduce(image_resize, vcat, [img_list; logo_dir])

    oys, oxs = size(vcat_img)
    MaxSize, ScaleFactor = 5, 5
    imgSize = oys * oxs / (ScaleFactor * 2^20) / MaxSize # 1 mebibyte = 2^20 bytes
    (imgSize > 1 ) && (vcat_img =  imresize(vcat_img, ratio = sqrt(1/imgSize)) )

    save(outs_dir, vcat_img)

    rm.(img_list)

    @info "Image Created: $outs_dir"
end # function
