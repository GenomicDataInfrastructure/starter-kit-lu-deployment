# create a bot to auto-approve applications
curl -X POST http://localhost:3000/api/users/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
        "userid": "approver-bot", "name": "Approver Bot", "email": null
    }'

# create an organisation which will hold all data
curl -X POST http://localhost:3000/api/organizations/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
            "organization/id": "gdi",
            "organization/short-name": {
                "en": "gdi"
            },
            "organization/name": {
                "en": "gdi"
            }
        }'

# create a license for a resource
curl -X POST http://localhost:3000/api/licenses/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
            "licensetype": "text",
            "organization": {
                "organization/id": "gdi"
            },
            "localizations": {
                "en": {
                    "title": "Example License",
                    "textcontent": "By applying for this resource you accept the licenses and terms."
                }
            }
        }'

# create a resource is the dataset identifier
curl -X POST http://localhost:3000/api/resources/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
            "resid": "urn:gdi:example-dataset",
            "organization": {
                "organization/id": "gdi"
            },
            "licenses": [1]
        }'

# create a form for the dataset application process
curl -X POST http://localhost:3000/api/forms/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
            "form/title": "Example Form",
            "form/internal-name": "Example Form",
            "form/external-title": {
                "en": "Example Form"
            },
            "form/fields": [
                {
                "field/title": {
                    "en": "Reason"
                },
                "field/type": "text",
                "field/max-length": null,
                "field/optional": true
                }
            ],
            "organization": {
                "organization/id": "gdi"
            }
        }'

# create a workflow (DAC) to handle the application, here the auto-approve bot will handle it
curl -X POST http://localhost:3000/api/workflows/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
            "organization": {
                "organization/id": "gdi"
            },
            "title": "Example Workflow",
            "forms": [
                {
                    "form/id": 1
                }
            ],
            "type": "workflow/default",
            "handlers": [
                "approver-bot"
            ],
            "licenses": []
        }'

# finally create a catalogue item, so that the dataset shows up on the main page
curl -X POST http://localhost:3000/api/catalogue-items/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
            "organization": {
                "organization/id": "gdi"
            },
            "form": null,
            "resid": 1,
            "wfid": 1,
            "localizations": {
                "en": {
                    "title": "Example Dataset"
                }
            },
            "enabled": true,
            "archived": false
        }'
