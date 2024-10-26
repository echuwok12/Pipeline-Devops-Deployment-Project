# Use the official NGINX image as the base image
FROM nginx:latest

# Remove the default NGINX index page
RUN rm -rf /usr/share/nginx/html/*

# Copy your HTML files to the NGINX web root directory
COPY . /usr/share/nginx/html

# Expose port 80 to allow external access
EXPOSE 80

# Start the NGINX server
CMD ["nginx", "-g", "daemon off;"]
