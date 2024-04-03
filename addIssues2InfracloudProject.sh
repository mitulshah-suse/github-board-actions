owner_name="rancher"
repo_list="cis-operator rancher qa-tasks"
label_name="team/infracloud"
project_number=67

#Fetch project ID using project number

project_id=`gh api graphql -f query="
query{
    repository(owner: \"${owner_name}\", name: \"rancher\") {
        projectV2(number: ${project_number}) {
            id
        }
    }
}" --jq '.data.repository.projectV2.id'`

echo $project_id

for repo_name in $repo_list
do
    #Fetch issues from the repo which are currently not being tracked in the project
    issues=`gh api graphql -f query="
    query{
        repository(owner: \"${owner_name}\", name: \"${repo_name}\"){
            issues(first: 100, states: OPEN, labels: \"${label_name}\") {
                nodes{
                    number
                    id
                    projectsV2(first: 100){
                        nodes{
                            id
                            number
                        }
                    }
                }
            }
        }
    }" --jq ".data.repository.issues.nodes | map(select((.projectsV2.nodes == [] or all(.projectsV2.nodes[]; .number != ${project_number})))) | .[].id"`

    echo $issues

    for issue_id in $issues
    do
        echo "Adding $issue_id to $project_id"
        id=`gh api graphql -f query="
        mutation {
            addProjectV2ItemById(input: {contentId: \"${issue_id}\", projectId: \"${project_id}\"}) {
                item { 
                    id
                }
            }
        }"`
        echo $id
    done
done

#Fetch rancherlabs/image-scanning repo issues with team/infracloud label
issues=`gh api graphql -f query="
query{
    repository(owner: "rancherlabs", name: "image-scanning"){
        issues(first: 100, states: OPEN, labels: \"${label_name}\") {
            nodes{
                number
                id
                projectsV2(first: 100){
                    nodes{
                        id
                        number
                    }
                }
            }
        }
    }
}" --jq ".data.repository.issues.nodes | map(select((.projectsV2.nodes == [] or all(.projectsV2.nodes[]; .number != ${project_number})))) | .[].id"`

echo $issues

#Adding rancherlabs/imagescanning issues to Infracloud project board
for issue_id in $issues
do
    echo "Adding $issue_id to $project_id"
    id=`gh api graphql -f query="
    mutation {
        addProjectV2ItemById(input: {contentId: \"${issue_id}\", projectId: \"${project_id}\"}) {
            item { 
                id
            }
        }
    }"`
    echo $id
done
