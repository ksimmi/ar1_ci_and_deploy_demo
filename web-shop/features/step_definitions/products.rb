Допустим("залогинен пользователь с email {string} и паролем {string}") do |email, password|
  visit('/admin/products')
  within('#new_user') do
    fill_in('Email', with: email)
    fill_in('Password', with: password)
    click_button('Log in')
  end
end

Если("он создает продукт с данными:") do |table|
  table.hashes.each do |hash|
    visit('/admin/products/new')
    within('#new_product') do
      select(hash[:category], from: 'Category')
      fill_in('Title', with: hash[:title])
      fill_in('Description', with: hash[:description])
      fill_in('Price', with: hash[:price])
      click_button('Create Product')
    end
  end
end

То("продукт {string} видно в списке продуктов") do |title|
  visit('/admin/products')
  expect(page).to have_xpath("//table[@id='index_table_products']//aasdasd[contains(text(), '#{title}')]")
 # '#index_table_products'
 sleep(2)

end
