#!/bin/bash

# Update the package list and install necessary packages
sudo yum update -y
sudo yum install -y httpd

# Start the Apache HTTP server
sudo systemctl start httpd
sudo systemctl enable httpd

# Create the directory for your HTML files
sudo mkdir -p /var/www/html

# Create the HTML file
cat <<EOF | sudo tee /var/www/html/index.html > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Users List</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
      background-color: #f4f4f9;
    }
    h1 {
      color: #333;
    }
    .user-list {
      margin-top: 20px;
    }
    .user-item {
      background-color: #fff;
      border: 1px solid #ddd;
      padding: 10px;
      margin-bottom: 10px;
      border-radius: 5px;
    }
    .user-item span {
      font-weight: bold;
    }
    .form-container {
      background-color: #fff;
      border: 1px solid #ddd;
      padding: 20px;
      margin-bottom: 20px;
      border-radius: 5px;
    }
    .form-container input {
      padding: 10px;
      margin: 5px;
      width: 200px;
      border-radius: 5px;
      border: 1px solid #ddd;
    }
    .form-container button {
      padding: 10px 20px;
      background-color: #4CAF50;
      color: white;
      border: none;
      border-radius: 5px;
      cursor: pointer;
    }
    .form-container button:hover {
      background-color: #45a049;
    }
  </style>
</head>
<body>

  <h1>User List</h1>

  <!-- Form to add new user -->
  <div class="form-container">
    <h3>Add New User</h3>
    <form id="user-form">
      <input type="text" id="name" placeholder="Enter Name" required />
      <input type="email" id="email" placeholder="Enter Email" required />
      <button type="submit">Add User</button>
    </form>
  </div>

  <div id="user-container" class="user-list">
    <!-- Users will be listed here -->
  </div>

  <script>
    // Function to fetch users from the server and display them
    const fetchUsers = async () => {
      try {
        const response = await fetch('http://10.0.2.10:3000/users'); // Fetch from the API
        if (response.ok) {
          const users = await response.json(); // Parse the response as JSON

          const userContainer = document.getElementById('user-container');
          userContainer.innerHTML = ''; // Clear previous content

          if (users.length > 0) {
            users.forEach(user => {
              // Create a new div for each user and add it to the user container
              const userDiv = document.createElement('div');
              userDiv.classList.add('user-item');
              userDiv.innerHTML = \`
                <p><span>Name:</span> \${user.name}</p>
                <p><span>Email:</span> \${user.email}</p>
              \`;
              userContainer.appendChild(userDiv);
            });
          } else {
            userContainer.innerHTML = '<p>No users found.</p>';
          }
        } else {
          console.error('Failed to fetch users');
          document.getElementById('user-container').innerHTML = '<p>Error loading users.</p>';
        }
      } catch (error) {
        console.error('Error:', error);
        document.getElementById('user-container').innerHTML = '<p>Error loading users.</p>';
      }
    };

    // Function to handle form submission and add a new user
    const addUser = async (event) => {
      event.preventDefault(); // Prevent the default form submission

      const name = document.getElementById('name').value;
      const email = document.getElementById('email').value;

      // Check if name and email are provided
      if (!name || !email) {
        alert('Both name and email are required!');
        return;
      }

      try {
        // Send POST request to add the new user
        const response = await fetch('http://localhost:3000/users', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ name, email }), // Send the data as JSON
        });

        if (response.ok) {
          const newUser = await response.json(); // Parse the response as JSON
          // Fetch and update the user list after adding the new user
          fetchUsers();
        } else {
          console.error('Failed to add user');
        }
      } catch (error) {
        console.error('Error:', error);
      }

      // Reset the form fields
      document.getElementById('user-form').reset();
    };

    // Event listener for form submission
    document.getElementById('user-form').addEventListener('submit', addUser);

    // Fetch users when the page loads
    window.onload = fetchUsers;
  </script>

</body>
</html>
EOF

# Set the correct permissions for the HTML file
sudo chmod 644 /var/www/html/index.html

# Ensure Apache server is running and enabled
sudo systemctl start httpd
sudo systemctl enable httpd

# Open port 80 (HTTP) in the firewall
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --reload
