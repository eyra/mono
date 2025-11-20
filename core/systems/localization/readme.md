# The localization system is a system that will help with enforcing the deterministic translation rules we have established.

### Browser detection flow
1. Take Accept-Language header from the request
2. Parse it to get the list of preferred languages
3. Match the preferred languages against the supported languages
4. If a match is found, set the locale to the matched language
5. If no match is found, set the locale to the default language (EN)


# Signup/Signin Page request 
- We use the Browser detection flow to determine the locale.

# Signup/Signin Page request met add_to_panl 
- We use NL because Panl is always in NL.

# Landing Page
- If the user is logged in:
    - Dashboard is shown:
        - If the user is a panl participant:
            - We use the browser detection flow to determine the locale.
        - If the user is not a panl participant:
            - We use EN.
- If the user is not logged in:
    - We use the browser detection flow to determine the locale.

# Cms page
1. CMS page is always in EN.

# Assignment page
How do we determine what an assignment page is??

Assignment page:
- Assignment detail page
- Assignment submission page
- Assignment Advert page 
- 
