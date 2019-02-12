def copy_image_fixture(product, file)
  fixtures_path = Rails.root.join('app', 'assets', 'images', 'fixtures', "#{file}.jpg")

  product.picture.attach(io: File.open(fixtures_path), filename: "#{file}.jpg")
end

categories = {
  cpu: Category.create!(name: 'CPUs'),
  ram: Category.create!(name: 'RAM'),
  mb: Category.create!(name: 'Motherboards'),
  hdd: Category.create!(name: 'HDDs')
}


cpu = Product.create!(title: 'Intel Core i7', price: 300, category: categories[:cpu])
copy_image_fixture(cpu, :cpu)

ram = Product.create!(title: '4GB DDR3 RAM', price: 40, category: categories[:ram])
copy_image_fixture(ram, :ram)

hdd = Product.create!(title: '1TB Seagate HDD', price: 60, category: categories[:hdd])
copy_image_fixture(hdd, :hdd)

mb = Product.create!(title: 'Asus P5Q3', price: 120, category: categories[:mb])
copy_image_fixture(mb, :mb)

User.create(
        name: 'Admin',
        email: 'admin@example.com',
        password: 'Passw0rd',
        password_confirmation: 'Passw0rd',
        is_admin: true
)