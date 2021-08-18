from mock import patch, MagicMock
import pytest

from db.errors import EntityDoesNotExist, ResourceIsNotDeployed
from db.repositories.workspace_services import WorkspaceServiceRepository
from models.domain.resource import Deployment, Status, ResourceType
from models.domain.workspace_service import WorkspaceService
from models.schemas.workspace_service import WorkspaceServiceInCreate


@pytest.fixture
def basic_workspace_service_request():
    return WorkspaceServiceInCreate(workspaceServiceType="workspace-service-type", properties={"display_name": "test", "description": "test"})


@pytest.fixture
def workspace_service_repo():
    with patch('azure.cosmos.CosmosClient') as cosmos_client_mock:
        yield WorkspaceServiceRepository(cosmos_client_mock)


@pytest.fixture
def workspace_service():
    workspace_service = WorkspaceService(
        id="000000d3-82da-4bfc-b6e9-9a7853ef753e",
        resourceTemplateVersion="0.1.0",
        resourceTemplateParameters={},
        resourceTemplateName="my-workspace-service",
    )
    return workspace_service


def test_get_active_workspace_services_for_workspace_queries_db(workspace_service_repo):
    workspace_service_id = "000000d3-82da-4bfc-b6e9-9a7853ef753e"
    workspace_service_repo.query = MagicMock()
    workspace_service_repo.query.return_value = []

    workspace_service_repo.get_active_workspace_services_for_workspace(workspace_service_id)

    workspace_service_repo.query.assert_called_once_with(query='SELECT * FROM c WHERE c.resourceType = "workspace-service" AND c.deleted = false AND c.workspaceId = "000000d3-82da-4bfc-b6e9-9a7853ef753e"')


def test_get_deployed_workspace_service_by_id_raises_resource_is_not_deployed_if_not_deployed(workspace_service_repo, workspace_service):
    workspace_service_id = "000000d3-82da-4bfc-b6e9-9a7853ef753e"
    service = workspace_service
    service.deployment = Deployment(status=Status.NotDeployed)

    workspace_service_repo.get_workspace_service_by_id = MagicMock(return_value=service)

    with pytest.raises(ResourceIsNotDeployed):
        workspace_service_repo.get_deployed_workspace_service_by_id(workspace_service_id)


def test_get_workspace_service_by_id_raises_entity_does_not_exist_if_no_available_services(workspace_service_repo):
    workspace_service_id = "000000d3-82da-4bfc-b6e9-9a7853ef753e"
    workspace_service_repo.query = MagicMock()
    workspace_service_repo.query.return_value = []

    with pytest.raises(EntityDoesNotExist):
        workspace_service_repo.get_workspace_service_by_id(workspace_service_id)


def test_get_workspace_service_by_id_queries_db(workspace_service_repo, workspace_service):
    workspace_service_id = "000000d3-82da-4bfc-b6e9-9a7853ef753e"
    workspace_service_repo.query = MagicMock()
    workspace_service_repo.query.return_value = [workspace_service]

    workspace_service_repo.get_workspace_service_by_id(workspace_service_id)

    workspace_service_repo.query.assert_called_once_with(query='SELECT * FROM c WHERE c.deleted = false AND c.resourceType = "workspace-service" AND c.id = "000000d3-82da-4bfc-b6e9-9a7853ef753e"')


@patch('db.repositories.workspace_services.WorkspaceServiceRepository.validate_input_against_template')
def test_create_workspace_service_item_creates_a_workspace_with_the_right_values(validate_input_mock, workspace_service_repo, basic_workspace_service_request, basic_workspace_service_template):
    workspace_id = "000000d3-82da-4bfc-b6e9-9a7853ef753e"
    workspace_service_to_create = basic_workspace_service_request

    resource_template = basic_workspace_service_template
    resource_template.required = ["display_name", "description"]

    validate_input_mock.return_value = basic_workspace_service_request.workspaceServiceType

    workspace_service = workspace_service_repo.create_workspace_service_item(workspace_service_to_create, workspace_id)

    assert workspace_service.resourceTemplateName == basic_workspace_service_request.workspaceServiceType
    assert workspace_service.resourceType == ResourceType.WorkspaceService
    assert workspace_service.deployment.status == Status.NotDeployed
    assert workspace_service.workspaceId == workspace_id


@patch('db.repositories.workspace_services.WorkspaceServiceRepository.validate_input_against_template')
def test_create_workspace_item_raises_value_error_if_template_is_invalid(validate_input_mock, workspace_service_repo, basic_workspace_service_request):
    workspace_id = "000000d3-82da-4bfc-b6e9-9a7853ef753e"
    workspace_service_to_create = basic_workspace_service_request
    validate_input_mock.side_effect = ValueError

    with pytest.raises(ValueError):
        workspace_service_repo.create_workspace_service_item(workspace_service_to_create, workspace_id)
