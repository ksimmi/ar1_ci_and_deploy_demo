ActiveAdmin.register Product do
  form do |f|
    f.inputs do
      f.input :category
      f.input :title
      f.input :description
      f.input :price
      if f.object.picture.attached?
        f.input :picture,
          :as => :file,
          :hint => image_tag(
            url_for(
              f.object.picture.variant(
                combine_options: {
                  gravity: 'Center',
                  crop: '50x50+0+0'
                }
              )
            )
          )
        else
          f.input :picture, :as => :file
      end
    end
    f.actions
  end

  index do
    selectable_column
    id_column
    column :picture do |product|
      if product.picture.attached?
        image_tag product.picture.variant(
          combine_options: {
            gravity: 'Center',
            crop: '50x50+0+0'
          }
        )
      end
    end

    column :title do |product|
      link_to product.title, admin_product_path(product)
    end

    column :price
    column :category
    actions
  end

  show do
    attributes_table do
      row :image do |product|
        if product.picture.attached?
          image_tag product.picture.variant(
            combine_options: {
              gravity: 'Center',
              crop: '50x50+0'
            }
          )
        end
      end

      row :title
      row :category
      row :price
      row :description
    end
    active_admin_comments
  end

  permit_params :category_id, :title, :description, :price, :picture
end
